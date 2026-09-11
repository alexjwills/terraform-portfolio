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

resource "aws_s3_bucket" "example" {
  bucket = var.bucket_name

  tags = {
    Environment = var.environment
  }
}
