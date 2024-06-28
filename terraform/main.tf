terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket         = "gsk-terraform-statefile"
    key            = "terraformstate-usermanagement/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "gsk-terraform-lock"
    encrypt        = true
  }

}