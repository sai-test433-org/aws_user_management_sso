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

#inline policy for the permission sets
data "aws_iam_policy_document" "s3_read_policy" {
  statement {
    sid = "1"
    actions = [
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation",
    ]
    resources = [
      "arn:aws:s3:::*",
    ]
  }
}

#permission set and inline policy attachment
resource "aws_ssoadmin_permission_set_inline_policy" "s3_read_inline_policy" {
    for_each = {
      for ps in local.permission_set :
      ps.name => ps
      if !ps.managed
    }

  inline_policy      = data.aws_iam_policy_document.s3_read_policy.json
  instance_arn       = tolist(data.aws_ssoadmin_instances.example.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.ReadOnlyAccess[each.key].arn
}

data "aws_ssoadmin_permission_set" "permission_sets" {
  for_each = {
    for access in local.flattened_access :
    access.permission_set.name => access
  }

  instance_arn = tolist(data.aws_ssoadmin_instances.example.arns)[0]
  name         = each.key
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
    data.aws_ssoadmin_permission_set.permission_sets[each.value.permission_set.name].arn :
    aws_ssoadmin_permission_set.ReadOnlyAccess["${each.value.group_name}-${each.value.permission_set.name}"].arn
  )
  principal_id   = aws_identitystore_group.groups[each.value.group_name].group_id
  principal_type = "GROUP"
  target_id      = each.value.account_id
  target_type    = "AWS_ACCOUNT"
}
