# data "aws_ssoadmin_instances" "example" {}


locals {
  users             = jsondecode(file("${path.module}/users.json"))
  group_memberships = jsondecode(file("${path.module}/user_groups.json"))
  account_access    = jsondecode(file("${path.module}/account_access.json"))
  flattened_memberships = flatten([
    for group in local.group_memberships : [
      for user in group.users : {
        group_name = group.group_name
        user_name  = user
      }
    ]
  ])
}

# Create IAM Identity Center users
resource "aws_identitystore_user" "users" {
  for_each = { for user in local.users : user.user_name => user }

  identity_store_id = "d-9067e37c95" # Replace with your Identity Store ID
  user_name         = each.value.user_name
  display_name      = each.value.display_name
  name {
    family_name = each.value.family_name
    given_name  = each.value.given_name
  }
}

# Create IAM Identity Center groups
resource "aws_identitystore_group" "groups" {
  for_each = { for group in local.group_memberships : group.group_name => group }

  identity_store_id = "d-9067e37c95" # Replace with your Identity Store ID
  display_name      = each.key
}

# Add users to groups
# resource "aws_identitystore_group_membership" "group_memberships" {
#   for_each = { for group in local.group_memberships : "${group.group_name}-${join(",", group.users)}" => {
#     group_name = group.group_name,
#     users      = group.users
#   } }

#   identity_store_id = "d-9067e37c95"  # Replace with your Identity Store ID
#   group_id          = aws_identitystore_group.groups[each.value.group_name].group_id

#   # Assign member_ids as a list of strings
# #   member_id         = [for user in each.value.users : aws_identitystore_user.users[user].user_id]
#     # member_id = flatten([for user in each.value.users : [aws_identitystore_user.users[user].user_id]])
#     member_id = []
#   depends_on = [
#     aws_identitystore_group.groups,
#     aws_identitystore_user.users
#   ]
# }

## Add users to groups
#resource "aws_identitystore_group_membership" "group_memberships" {
#  for_each = { for group in local.group_memberships : "${group.group_name}-${user}" => user for user in group.users }
#
#  identity_store_id = "d-9067e37c95"  # Replace with your Identity Store ID
#  group_id          = aws_identitystore_group.groups[each.value.group_name].group_id
#  member_id         = aws_identitystore_user.users[each.value].user_id
#
#  depends_on = [
#    aws_identitystore_group.groups,
#    aws_identitystore_user.users
#  ]
#}




# # Create IAM Identity Center group memberships
# resource "aws_identitystore_group_membership" "group_memberships" {
#   for_each = toset([for group in local.group_memberships, user in group.users : "${group.group_name}-${user}"])

#   identity_store_id = "d-9067e37c95"  # Replace with your Identity Store ID
#   group_id          = aws_identitystore_group.groups[split("-", each.key)[0]].id
#   member_id         = aws_identitystore_user.users[split("-", each.key)[1]].id
# }

resource "aws_identitystore_group_membership" "group_memberships" {
  for_each = {
    for membership in local.flattened_memberships : "${membership.group_name}-${membership.user_name}" => membership
  }

  identity_store_id = "d-9067e37c95" # Replace with your Identity Store ID
  group_id          = aws_identitystore_group.groups[each.value.group_name].group_id
  member_id         = aws_identitystore_user.users[each.value.user_name].user_id
}