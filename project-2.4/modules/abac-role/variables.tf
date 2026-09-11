variable "role_name" {
    description = "Name for the IAM role. Must be unique within the account"
    type = string
}

variable "department" {
    description = "Department this role belongs to. Used both for naming and as the role's ABAC tag"
    type = string
}
variable "account_id" {
  description = "AWS account ID - supply your own, never commit a real one"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name - supply your own, never commit a real one"
  type        = string
}
