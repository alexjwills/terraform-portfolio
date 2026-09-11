output "role_arn" {
    description = "ARN of this ABAC role"
    value = aws_iam_role.abac_role.arn
}

output "role_name" {
  description = "Name of this ABAC role"
  value       = aws_iam_role.abac_role.name
}