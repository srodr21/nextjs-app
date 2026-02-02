# =============================================================================
# Security Groups
# =============================================================================
# Security groups act as virtual firewalls for resources.
# They control inbound (ingress) and outbound (egress) traffic.

# -----------------------------------------------------------------------------
# ALB Security Group
# -----------------------------------------------------------------------------
# Allows HTTP (80) and HTTPS (443) traffic from the internet.
# This is the only resource directly accessible from the internet.

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  # Allow HTTP from anywhere (will redirect to HTTPS if configured)
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # 0.0.0.0/0 = all IP addresses
  }

  # Allow HTTPS from anywhere
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic (needed to reach ECS tasks)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # -1 = all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# -----------------------------------------------------------------------------
# ECS Tasks Security Group
# -----------------------------------------------------------------------------
# Only allows traffic from the ALB on the container port.
# This ensures ECS tasks are not directly accessible from the internet.

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = module.vpc.vpc_id

  # Only allow traffic from ALB on the container port
  ingress {
    description     = "Allow traffic from ALB only"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]  # Only from ALB security group
  }

  # Allow all outbound traffic (needed for ECR, external APIs, etc.)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-tasks-sg"
  }
}
