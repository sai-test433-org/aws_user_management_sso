## data "aws_ssoadmin_instances" "example" {}
#
#provider "aws" {
#  region = "us-east-1"  # Replace with your desired region
#}
#
## Create IAM Identity Center user
#resource "aws_identitystore_user" "sai_test" {
#  identity_store_id = "d-9067e37c95"  # Replace with your Identity Store ID
#  user_name         = "sai_test"
#  display_name      = "Sai Test"
#  name {
#    family_name = "Test"
#    given_name  = "Sai"
#  }
#}
#
## Create IAM Identity Center group
#resource "aws_identitystore_group" "test_group" {
#  identity_store_id = "d-9067e37c95"  # Replace with your Identity Store ID
#  display_name      = "Test Group"
#}
#
## Add user to group
#resource "aws_identitystore_group_membership" "test_group_membership" {
#  identity_store_id = "d-9067e37c95"  # Replace with your Identity Store ID
#  group_id          = aws_identitystore_group.test_group.group_id
#  member_id         = aws_identitystore_user.sai_test.user_id
#}
#
## Create a Permission Set with Admin permissions
## resource "aws_ssoadmin_permission_set" "admin_permission_set" {
##   instance_arn = "arn:aws:sso:::instance/ssoins-722312b6e3f7713f"  # Replace with your SSO instance ARN
##   name         = "AdminPermissionSet"
##   description  = "Admin permission set"
#
##   managed_policies = [
##     "arn:aws:iam::aws:policy/AdministratorAccess"
##   ]
## }
#
## Assign the Permission Set to the User
## resource "aws_ssoadmin_account_assignment" "user_admin_assignment" {
##   instance_arn       = "arn:aws:sso:::instance/ssoins-XXXXXXXXXXXX"  # Replace with your SSO instance ARN
##   permission_set_arn = aws_ssoadmin_permission_set.admin_permission_set.arn
##   principal_id       = aws_identitystore_user.sai_test.user_id
##   principal_type     = "USER"
##   target_id          = "590184113190"  # Replace with your AWS account ID
## }
#
## resource "aws_ssoadmin_permission_set" "example" {
##   name         = "Example"
##   instance_arn = "arn:aws:sso:::instance/ssoins-722312b6e3f7713f"
## }
#
## data "aws_iam_policy_document" "example" {
##   statement {
##     sid = "1"
#
##     actions = [
##       "*"
##     ]
#
##     resources = [
##       "*",
##     ]
##   }
## }
#
## resource "aws_ssoadmin_permission_set_inline_policy" "example" {
##   inline_policy      = data.aws_iam_policy_document.example.json
##   instance_arn       = "arn:aws:sso:::instance/ssoins-722312b6e3f7713f"
##   permission_set_arn = aws_ssoadmin_permission_set.example.arn
#
#
#data "aws_ssoadmin_permission_set" "example" {
#  instance_arn = "arn:aws:sso:::instance/ssoins-722312b6e3f7713f"
#  name         = "AWSReadOnlyAccess"
#}
#
#
#
#resource "aws_ssoadmin_account_assignment" "example" {
#  instance_arn       = "arn:aws:sso:::instance/ssoins-722312b6e3f7713f"
#  permission_set_arn = data.aws_ssoadmin_permission_set.example.arn
#
#  principal_id   = aws_identitystore_group.test_group.group_id
#  principal_type = "GROUP"
#
#  target_id   = "590184113190"
#  target_type = "AWS_ACCOUNT"
#}