variable "role_name" {
    description = "Name for the IAM role - must be unique within the account"
    type = string
}

variable "department" {
    description = "Department this role/policy pair grants access to (e.g. engineering, finance)"
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
