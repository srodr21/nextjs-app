# =============================================================================
# IAM Roles and Policies
# =============================================================================
# IAM roles define what permissions ECS tasks have.
# Two roles are needed:
# 1. Task Execution Role: For ECS to start containers (pull images, logs)
# 2. Task Role: For what the running container can do (S3, DynamoDB, etc.)

# -----------------------------------------------------------------------------
# ECS Task Execution Role
# -----------------------------------------------------------------------------
# This role is used by ECS itself to:
# - Pull container images from ECR
# - Write logs to CloudWatch
# - Get secrets from Secrets Manager (if used)

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-ecs-execution-role"

  # Trust policy: Who can assume this role?
  assume_role_policy = jsonencode({
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

  tags = {
    Name = "${var.project_name}-ecs-execution-role"
  }
}

# Attach the AWS managed policy for ECS task execution
# This includes permissions for ECR, CloudWatch Logs, and Secrets Manager
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# -----------------------------------------------------------------------------
# ECS Task Role
# -----------------------------------------------------------------------------
# This role is used by the running container to access AWS services.
# Add policies here for services your app needs (S3, DynamoDB, etc.)

resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
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

  tags = {
    Name = "${var.project_name}-ecs-task-role"
  }
}

# -----------------------------------------------------------------------------
# Example: Add permissions for your task role
# -----------------------------------------------------------------------------
# Uncomment and modify these examples based on what your app needs.

# Example: S3 access
# resource "aws_iam_role_policy" "ecs_task_s3" {
#   name = "${var.project_name}-s3-policy"
#   role = aws_iam_role.ecs_task.id
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:ListBucket"
#         ]
#         Resource = [
#           "arn:aws:s3:::your-bucket-name",
#           "arn:aws:s3:::your-bucket-name/*"
#         ]
#       }
#     ]
#   })
# }

# Example: Secrets Manager access (for database credentials, API keys, etc.)
# resource "aws_iam_role_policy" "ecs_task_secrets" {
#   name = "${var.project_name}-secrets-policy"
#   role = aws_iam_role.ecs_task.id
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "secretsmanager:GetSecretValue"
#         ]
#         Resource = [
#           "arn:aws:secretsmanager:${var.aws_region}:*:secret:${var.project_name}/*"
#         ]
#       }
#     ]
#   })
# }
