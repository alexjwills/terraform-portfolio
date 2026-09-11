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

resource "aws_organizations_policy" "example_SCP" {
  name = "DenyRootAccountUsage"
  type = "SERVICE_CONTROL_POLICY"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:PrincipalType" = "Root"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "cross_account_policy" {
  name = "CrossAccountAccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::999999999999:root"
        }
      }
    ]
  })
}

resource "aws_ssoadmin_permission_set" "readonly_permset" {
  name             = "ReadOnlyPermissionSet"
  instance_arn     = "arn:aws:sso:::instance/ssoins-4567890123456789"
  session_duration = "PT2H"
}

resource "aws_ssoadmin_permission_set_inline_policy" "readonly_permset_policy" {
  instance_arn       = aws_ssoadmin_permission_set.readonly_permset.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.readonly_permset.arn
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:Get*", "s3:List*"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}