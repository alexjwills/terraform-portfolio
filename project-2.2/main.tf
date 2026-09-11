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
    name = "delegated-power-user-tf"
    permissions_boundary = aws_iam_policy.iam_boundary.arn
}

resource "aws_iam_user_policy_attachment" "power_user_attachment" {
    user = aws_iam_user.delegated_power_user.name
    policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}