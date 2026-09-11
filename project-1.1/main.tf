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

resource "aws_s3_bucket" "first_bucket" {
  bucket = "tf-portfolio-1-1-ajw-20260309"

  tags = {
    Project = "terraform-portfolio-1.1"
    Purpose = "learning-state-and-plan-apply"
  }
}