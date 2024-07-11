locals {
  account_access    = jsondecode(file("${path.module}/account_access.json"))
  flattened_memberships = flatten([
    for group in local.group_memberships : [
      for user in group.users : {
        group_name = group.group_name
        user_name  = user
      }
    ]
  ])

  flattened_access = flatten([
    for access in local.account_access : [
      for permission_set in access.permission_sets : {
        group_name     = access.group_name
        permission_set = permission_set
        account_id     = access.account_id
      }
    ]
  ])
    permission_set = jsondecode(file("${path.module}/custom_permission_sets.json"))
    permission_set_policies = flatten([for ps in local.permission_set : [for policy in lookup(ps, "inline_policies",[]) : { key = "${ps.name}", permission_set_name = ps.name, policy = policy }]])
    unmanaged_permission_sets = flatten([ for ps in local.permission_set : ps.managed == false ? [{name = ps.name}] : []])
}

data "aws_ssoadmin_instances" "example" {}


#create permission sets
resource "aws_ssoadmin_permission_set" "ReadOnlyAccess" {
  for_each = {
    for access in local.flattened_access :
    # "${access.group_name}-${access.permission_set.name}" => access
    "${access.permission_set.name}" => access
    if !access.permission_set.managed
  }

  instance_arn = tolist(data.aws_ssoadmin_instances.example.arns)[0]
  name         = each.value.permission_set.name
  description  = "Custom permission set for ${each.value.permission_set.name}"
}

resource "aws_ssoadmin_permission_set" "custom_permission_sets" {
  for_each = {
    for ps in local.permission_set :
    # "${access.group_name}-${access.permission_set.name}" => access
    "${ps.name}" => ps
    if !ps.managed
  }

  instance_arn = tolist(data.aws_ssoadmin_instances.example.arns)[0]
  name         = each.value.name
  # description  = "Custom permission set for ${each.value.permission_set.name}"
}

#inline policy for the permission sets
# data "aws_iam_policy_document" "s3_read_policy" {
#   statement {
#     sid = "1"
#     actions = [
#       "s3:ListAllMyBuckets",
#       "s3:GetBucketLocation",
#     ]
#     resources = [
#       "arn:aws:s3:::*",
#     ]
#   }
# }

# resource "aws_ssoadmin_permission_set" "custom_permission_sets" {
#   for_each ={
#     for ps in local.permission_set_policies : ps.key => {

#     name = ps.permission_set_name
#     instance_arn = tolist(data.aws_ssoadmin_instances.example.arns)[0]
#     session_duration = "PT2H"
#     }

#     name = each.name
#     instance_arn = each.instance_arn
#     session_duration = each.session_duration
#   }
# }

# resource "aws_ssoadmin_permission_set" "custom_permission_sets" {
#   for_each ={
#     for ps in local.permission_set_policies : ps.key => {

#     }

#     name = each.permission_set_name
#     instance_arn = tolist(data.aws_ssoadmin_instances.example.arns)[0]
#     session_duration = "PT2H"
#   }
# }

#permission set and inline policy attachment
resource "aws_ssoadmin_permission_set_inline_policy" "s3_read_inline_policy" {
for_each = {
  # for ps_policy in local.permission_set_policies : ps_policy.key => ps_policy
  for ps_policy in local.permission_set_policies : "${ps_policy.key}" => ps_policy
}



  inline_policy      = jsonencode(each.value.policy)
  instance_arn       = tolist(data.aws_ssoadmin_instances.example.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.custom_permission_sets[each.value.permission_set_name].arn
}

data "aws_ssoadmin_permission_set" "managed_permission_sets" {
  for_each = {
    for ps in local.permission_set :
    ps.name => ps
    if ps.managed
  }

  instance_arn = tolist(data.aws_ssoadmin_instances.example.arns)[0]
  name         = each.key
  # description  = "Custom permission set for ${each.key}"
}

resource "aws_ssoadmin_account_assignment" "account_assignments" {
  for_each = {
    for access in local.flattened_access :
    "${access.group_name}-${access.permission_set.name}-${access.account_id}" => access
  }

  #   depends_on = [
  #   aws_ssoadmin_permission_set.custom_permission_sets,
  #   data.aws_ssoadmin_permission_set.permission_sets
  # ]

  instance_arn = tolist(data.aws_ssoadmin_instances.example.arns)[0]
  permission_set_arn = (
    each.value.permission_set.managed ?
    data.aws_ssoadmin_permission_set.managed_permission_sets[each.value.permission_set.name].arn :
    aws_ssoadmin_permission_set.ReadOnlyAccess["${each.value.permission_set.name}"].arn
  )
  principal_id   = aws_identitystore_group.groups[each.value.group_name].group_id
  principal_type = "GROUP"
  target_id      = each.value.account_id
  target_type    = "AWS_ACCOUNT"
}
