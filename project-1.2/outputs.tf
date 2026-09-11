output "bucket_arn" {
  description = "This is the arn for the S3 bucket"
  value       = aws_s3_bucket.example.arn
}
