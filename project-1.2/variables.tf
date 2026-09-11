variable "bucket_name" {
  description = "Name of the S3 bucket to create"
  type        = string
}

variable "environment" {
  description = "The environment this S3 bucket belongs to"
  type        = string
  default     = "learning"
}