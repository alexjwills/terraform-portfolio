terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
   time = {
  source  = "hashicorp/time"
  version = "~> 0.9"
     }
}

backend "s3" {
    bucket = "tf-portfolio-ajw-20260907"
    key = "project-1.4/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform_portfolio_locks"
    profile = "portfolio"
    }
}

provider "aws" {
  region  = "us-east-1"
  profile = "portfolio"
}

resource "aws_s3_bucket" "terraform_online_storage" {
  bucket = "tf-portfolio-ajw-20260907"
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_online_storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform_portfolio_locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "time_sleep" "wait_10_seconds" {
  create_duration = "10s"
}

