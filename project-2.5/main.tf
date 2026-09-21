terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
      }
    }

provider "aws" {
    region = "us-east-1"
    profile = "portfolio"
}

resource "aws_ecr_repository" "abac_boto3_demo" {
    name = "abac-boto3-demo"
    force_delete = true
}

resource "aws_iam_role" "ecs_execution_role" {
    name = "ecs-execution-role-tf"

    assume_role_policy = jsonencode ({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                   Service = "ecs-tasks.amazonaws.com"
                }
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "ecs_role_attachment" {
    role = aws_iam_role.ecs_execution_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
    name = "ecs-task-role"
    tags = {
        department = "engineering"
    }

    assume_role_policy = jsonencode ({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "ecs-tasks.amazonaws.com"
                }
            }
        ]
    })
}

resource "aws_iam_policy" "abac_shared_policy" {
    name = "abac-department-access-policy-tf"
    description = "Grants S3 access where the requester's department tag matches the object's department tag"

    policy = jsonencode ({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "s3:GetObject"
                Effect = "Allow"
                Resource = "arn:aws:s3:::alexwills-amzn-s3-demo/*"
                Condition = {
                StringEquals = {
                    "s3:ExistingObjectTag/department" = "$${aws:PrincipalTag/department}"
                    }
                }
            },
            {
                Effect   = "Allow"
                Action   = "s3:ListBucket"
                Resource = "arn:aws:s3:::alexwills-amzn-s3-demo"
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "ecs_abac_attachment" {
    role = aws_iam_role.ecs_task_role.name
    policy_arn = aws_iam_policy.abac_shared_policy.arn
}

resource "aws_ecs_cluster" "abac_demo_cluster" {
    name = "abac-demo-cluster"
}

resource "aws_cloudwatch_log_group" "abac_demo_logs" {
    name = "/ecs/abac-demo-task"
}

resource "aws_ecs_task_definition" "abac_demo_task" {
    family = "abac-demo-task"
    requires_compatibilities = ["FARGATE"]
    network_mode = "awsvpc"
    cpu = "256"
    memory = "512"
    execution_role_arn = aws_iam_role.ecs_execution_role.arn
    task_role_arn = aws_iam_role.ecs_task_role.arn

    container_definitions = jsonencode ([
        {
            name = "ecr-abac-task-container",
            image = "${aws_ecr_repository.abac_boto3_demo.repository_url}:latest"
            environment = [
                {
                    name = "AWS_BUCKET_NAME"
                    value = "alexwills-amzn-s3-demo"
                }
            ]
            logConfiguration = {
                logDriver = "awslogs"
                options = {
                    "awslogs-group" = "/ecs/abac-demo-task"
                    "awslogs-region" = "us-east-1"
                    "awslogs-stream-prefix" = "ecs"
                }
            }
        }
    ])
    runtime_platform {
            cpu_architecture        = "ARM64"
            operating_system_family = "LINUX"
        }
}