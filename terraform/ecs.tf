# =============================================================================
# ECS (Elastic Container Service) Configuration
# =============================================================================
# ECS runs and manages your Docker containers.
# Fargate is the "serverless" launch type - no EC2 instances to manage.

# -----------------------------------------------------------------------------
# CloudWatch Log Group
# -----------------------------------------------------------------------------
# Container logs are sent to CloudWatch for viewing and debugging.

resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-logs"
  }
}

# -----------------------------------------------------------------------------
# ECS Cluster
# -----------------------------------------------------------------------------
# A cluster is a logical grouping of tasks and services.
# It doesn't cost anything by itself - you pay for the tasks running in it.

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"  # Enable for production monitoring
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# Cluster capacity providers for Fargate
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1           # Always run at least 1 task on regular Fargate
    weight            = 1
    capacity_provider = "FARGATE"
  }

  # Use Fargate Spot for cost savings (can be interrupted)
  # default_capacity_provider_strategy {
  #   weight            = 4           # 80% of tasks on Spot
  #   capacity_provider = "FARGATE_SPOT"
  # }
}

# -----------------------------------------------------------------------------
# ECS Task Definition
# -----------------------------------------------------------------------------
# The task definition is a blueprint for your container.
# It specifies what image to run, CPU/memory, environment variables, etc.

resource "aws_ecs_task_definition" "main" {
  family                   = var.project_name
  network_mode             = "awsvpc"  # Required for Fargate
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  # Enable ECS Exec for debugging (SSH into container)
  # runtime_platform {
  #   operating_system_family = "LINUX"
  #   cpu_architecture        = "X86_64"  # Use ARM64 for Graviton (cheaper)
  # }

  container_definitions = jsonencode([
    {
      name  = var.project_name
      image = "${aws_ecr_repository.main.repository_url}:latest"

      # Port mapping
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      # Environment variables for Next.js
      environment = [
        {
          name  = "PORT"
          value = tostring(var.container_port)
        },
        {
          name  = "NODE_ENV"
          value = var.node_env
        },
        {
          name  = "HOSTNAME"
          value = "0.0.0.0"  # Required for Next.js in Docker
        },
        # Next.js image optimization
        {
          name  = "NEXT_SHARP_PATH"
          value = var.nextjs_sharp_memory ? "/app/node_modules/sharp" : ""
        },
        # Trust proxy headers from ALB/CloudFront
        {
          name  = "TRUST_PROXY"
          value = "true"
        }
      ]

      # For secrets, use the secrets block
      # secrets = [
      #   {
      #     name      = "DATABASE_URL"
      #     valueFrom = "arn:aws:secretsmanager:region:account:secret:db-url"
      #   }
      # ]

      # Logging configuration
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.main.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      # If this container stops, stop the whole task
      essential = true

      # Container health check
      healthCheck = {
        command = [
          "CMD-SHELL",
          "node -e \"require('http').get('http://localhost:${var.container_port}${var.health_check_path}', (r) => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))\""
        ]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = var.container_start_period  # Grace period for startup
      }

      # Resource limits (optional, for better stability)
      # ulimits = [
      #   {
      #     name      = "nofile"
      #     softLimit = 65536
      #     hardLimit = 65536
      #   }
      # ]
    }
  ])

  tags = {
    Name = "${var.project_name}-task-definition"
  }
}

# -----------------------------------------------------------------------------
# ECS Service
# -----------------------------------------------------------------------------
# The service ensures the desired number of tasks are always running.
# If a task crashes, the service automatically starts a new one.

resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.min_capacity  # Start with min, auto-scaling handles the rest
  launch_type     = "FARGATE"

  # Enable deployment circuit breaker
  deployment_circuit_breaker {
    enable   = true
    rollback = true  # Automatically rollback on deployment failure
  }

  # Network configuration for Fargate
  network_configuration {
    subnets          = module.vpc.private_subnets  # Run in private subnets
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false  # No public IP (uses NAT Gateway for internet)
  }

  # Register tasks with the ALB target group
  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = var.project_name
    container_port   = var.container_port
  }

  # Deployment configuration
  deployment_minimum_healthy_percent = 100  # Keep all tasks during deployment
  deployment_maximum_percent         = 200  # Allow up to 2x tasks during deployment

  # Health check grace period (time to wait before checking health)
  health_check_grace_period_seconds = var.container_start_period

  # Enable ECS Exec for debugging (requires additional IAM permissions)
  # enable_execute_command = true

  # Spread tasks across AZs for high availability
  # placement_constraints are not supported with Fargate, it automatically spreads

  # Wait for ALB listener before creating service
  depends_on = [
    aws_lb_listener.http
  ]

  # Ignore changes to desired_count (managed by auto-scaling)
  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    Name = "${var.project_name}-service"
  }
}
