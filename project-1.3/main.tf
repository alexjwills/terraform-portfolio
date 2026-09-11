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

resource "aws_iam_role" "example_role" {
  name = "example-dependency-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "example_policy" {
  name        = "example-dependency-policy"
  description = "Allows read-only access to a specific s3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "example_attachment" {
  role       = aws_iam_role.example_role.name
  policy_arn = aws_iam_policy.example_policy.arn
}




variable "account_id" {
  description = "AWS account ID - supply your own, never commit a real one"
  type        = string
}
