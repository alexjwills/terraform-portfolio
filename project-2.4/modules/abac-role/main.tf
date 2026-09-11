resource "aws_iam_role" "abac_role" {
    name = var.role_name

    assume_role_policy = jsonencode ({
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

    tags = {
        department = var.department
     }
}