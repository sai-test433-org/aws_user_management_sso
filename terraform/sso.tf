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

  flattened_access = flatten([
    for access in local.account_access : [
      for permission_set in access.permission_sets : {
        group_name     = access.group_name
        permission_set = permission_set
        account_id     = access.account_id
      }
    ]
  ])
    permission_set = [
    for ps in local.flattened_access :
    {
      name    = ps.permission_set.name
      managed = ps.permission_set.managed
    }
  ]

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

resource "aws_identitystore_group_membership" "group_memberships" {
  for_each = {
    for membership in local.flattened_memberships : "${membership.group_name}-${membership.user_name}" => membership
  }

  identity_store_id = "d-9067e37c95" # Replace with your Identity Store ID
  group_id          = aws_identitystore_group.groups[each.value.group_name].group_id
  member_id         = aws_identitystore_user.users[each.value.user_name].user_id
}