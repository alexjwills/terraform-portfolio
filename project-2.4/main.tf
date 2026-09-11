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

module "engineering_role" {
  source      = "./modules/abac-role"
  role_name   = "ABAC-Engineering-Role-tf"
  department  = "engineering"
  account_id  = var.account_id
  bucket_name = var.bucket_name
}

module "finance_role" {
  source      = "./modules/abac-role"
  role_name   = "ABAC-Finance-Role-tf"
  department  = "finance"
  account_id  = var.account_id
  bucket_name = var.bucket_name
}

module "marketing_role" {
  source      = "./modules/abac-role"
  role_name   = "ABAC-Marketing-Role-tf"
  department  = "marketing"
  account_id  = var.account_id
  bucket_name = var.bucket_name
}

resource "aws_iam_policy" "abac_shared_policy" {
  name        = "ABAC-Department-Access-Policy-tf"
  description = "Grants S3 access where the requester's department tag matches the object's department tag"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = "arn:aws:s3:::${var.bucket_name}/*"
        Condition = {
          StringEquals = {
            "s3:ExistingObjectTag/department" = "$${aws:PrincipalTag/department}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "engineering_attachment" {
  role       = module.engineering_role.role_name
  policy_arn = aws_iam_policy.abac_shared_policy.arn
}

resource "aws_iam_role_policy_attachment" "finance_attachment" {
  role       = module.finance_role.role_name
  policy_arn = aws_iam_policy.abac_shared_policy.arn
}

resource "aws_iam_role_policy_attachment" "marketing_attachment" {
  role       = module.marketing_role.role_name
  policy_arn = aws_iam_policy.abac_shared_policy.arn
}

resource "aws_iam_policy" "iam_boundary" {
  name = "PowerUserBoundary-tf"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:Get*", "s3:List*", "iam:Get*", "iam:List*"]
        Resource = "*"
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_iam_user" "delegated_power_user" {
  name                 = "delegated-power-user-tf"
  permissions_boundary = aws_iam_policy.iam_boundary.arn
}

resource "aws_iam_user_policy_attachment" "power_user_attachment" {
  user       = aws_iam_user.delegated_power_user.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

variable "bucket_name" {
  description = "S3 bucket name - supply your own, never commit a real one"
  type        = string
}

variable "account_id" {
  description = "AWS account ID - supply your own, never commit a real one"
  type        = string
}
