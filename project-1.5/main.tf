terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "portfolio"
}

module "engineering_access" {
  source      = "./modules/iam-role-policy"
  role_name   = "engineering-role"
  department  = "engineering"
  bucket_name = var.bucket_name
  account_id  = var.account_id
}

module "finance_access" {
  source      = "./modules/iam-role-policy"
  role_name   = "finance-role"
  department  = "finance"
  bucket_name = var.bucket_name
  account_id  = var.account_id
}
variable "bucket_name" {
  description = "S3 bucket name - supply your own, never commit a real one"
  type        = string
}

variable "account_id" {
  description = "AWS account ID - supply your own, never commit a real one"
  type        = string
}
