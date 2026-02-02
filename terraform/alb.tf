# =============================================================================
# Application Load Balancer (ALB)
# =============================================================================
# ALB distributes incoming traffic across multiple ECS tasks.
# It also handles SSL termination (HTTPS) and health checks.

# -----------------------------------------------------------------------------
# Load Balancer
# -----------------------------------------------------------------------------

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false  # false = internet-facing (accessible from internet)
  load_balancer_type = "application"  # Layer 7 load balancer (HTTP/HTTPS)
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets  # ALB must be in public subnets

  # Enable deletion protection in production
  enable_deletion_protection = var.environment == "prod"

  # Enable access logs (recommended for production)
  # access_logs {
  #   bucket  = aws_s3_bucket.alb_logs.bucket
  #   prefix  = "alb"
  #   enabled = true
  # }

  # Enable HTTP/2 for better performance
  enable_http2 = true

  # Idle timeout (seconds) - increase for long-running requests
  idle_timeout = 60

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# -----------------------------------------------------------------------------
# Target Group
# -----------------------------------------------------------------------------
# Target group is where the ALB sends traffic.
# ECS tasks register themselves with this target group.

resource "aws_lb_target_group" "main" {
  name        = "${var.project_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"  # Required for Fargate (uses IP addresses, not instance IDs)

  # Health check configuration
  # ALB periodically checks if targets are healthy
  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path
    matcher             = var.health_check_matcher
    protocol            = "HTTP"
  }

  # Deregistration delay: how long to wait before removing unhealthy targets
  # Lower value = faster deployments, higher value = better for long requests
  deregistration_delay = 30

  # Stickiness (session affinity) - enable if your app needs it
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400  # 1 day
    enabled         = false  # Next.js is typically stateless
  }

  # Slow start - gradually increase traffic to new targets
  slow_start = 30  # 30 seconds

  tags = {
    Name = "${var.project_name}-tg"
  }

  # Ensure new target group is created before destroying old one
  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# HTTP Listener
# -----------------------------------------------------------------------------
# Handles traffic on port 80.
# Redirects to HTTPS when custom domain is configured, otherwise forwards to target.

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.create_dns_records ? "redirect" : "forward"

    # Redirect to HTTPS if custom domain is configured
    dynamic "redirect" {
      for_each = var.create_dns_records ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"  # Permanent redirect
      }
    }

    # Forward to target group if no custom domain
    target_group_arn = var.create_dns_records ? null : aws_lb_target_group.main.arn
  }
}

# -----------------------------------------------------------------------------
# HTTPS Listener (only if custom domain is configured without CloudFront)
# -----------------------------------------------------------------------------
# Handles traffic on port 443 with SSL/TLS.
# Only created if DNS is configured but CloudFront is disabled.

resource "aws_lb_listener" "https" {
  count = var.create_dns_records && !var.enable_cloudfront ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"  # Modern TLS policy
  certificate_arn   = aws_acm_certificate_validation.main[0].certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# -----------------------------------------------------------------------------
# Additional Listener Rules (Optional)
# -----------------------------------------------------------------------------
# Add custom routing rules based on path, headers, etc.

# Example: Route /api/* to a different target group
# resource "aws_lb_listener_rule" "api" {
#   listener_arn = aws_lb_listener.https[0].arn
#   priority     = 100
#
#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.api.arn
#   }
#
#   condition {
#     path_pattern {
#       values = ["/api/*"]
#     }
#   }
# }
