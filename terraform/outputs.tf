# =============================================================================
# Outputs
# =============================================================================
# These values are displayed after terraform apply completes.
# They provide important information about the created resources.

# -----------------------------------------------------------------------------
# Primary URL Output
# -----------------------------------------------------------------------------

output "app_url" {
  description = "Primary URL to access the application"
  value = var.create_dns_records ? (
    "https://${var.api_subdomain != "" ? "${var.api_subdomain}." : ""}${var.domain_name}"
  ) : (
    var.enable_cloudfront ? "https://${aws_cloudfront_distribution.main[0].domain_name}" : "http://${aws_lb.main.dns_name}"
  )
}

# -----------------------------------------------------------------------------
# Load Balancer Outputs
# -----------------------------------------------------------------------------

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_url" {
  description = "HTTP URL of the Application Load Balancer (direct, bypasses CloudFront)"
  value       = "http://${aws_lb.main.dns_name}"
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

# -----------------------------------------------------------------------------
# CloudFront Outputs
# -----------------------------------------------------------------------------

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for cache invalidation)"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.main[0].id : null
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.main[0].domain_name : null
}

output "cloudfront_url" {
  description = "CloudFront URL"
  value       = var.enable_cloudfront ? "https://${aws_cloudfront_distribution.main[0].domain_name}" : null
}

# -----------------------------------------------------------------------------
# ECR Outputs
# -----------------------------------------------------------------------------

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.main.repository_url
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.main.name
}

# -----------------------------------------------------------------------------
# ECS Outputs
# -----------------------------------------------------------------------------

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.main.name
}

# -----------------------------------------------------------------------------
# VPC Outputs
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

# -----------------------------------------------------------------------------
# WAF Outputs
# -----------------------------------------------------------------------------

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = var.enable_waf ? aws_wafv2_web_acl.main[0].arn : null
}

# -----------------------------------------------------------------------------
# Useful Commands
# -----------------------------------------------------------------------------

output "docker_login_command" {
  description = "Command to login to ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.main.repository_url}"
}

output "docker_build_push_commands" {
  description = "Commands to build and push Docker image"
  value       = <<-EOT
    # Build the image
    docker build -t ${var.project_name} .

    # Tag the image
    docker tag ${var.project_name}:latest ${aws_ecr_repository.main.repository_url}:latest

    # Push to ECR
    docker push ${aws_ecr_repository.main.repository_url}:latest
  EOT
}

output "ecs_update_command" {
  description = "Command to force new deployment (after pushing new image)"
  value       = "aws ecs update-service --cluster ${aws_ecs_cluster.main.name} --service ${aws_ecs_service.main.name} --force-new-deployment --region ${var.aws_region}"
}

output "cloudfront_invalidation_command" {
  description = "Command to invalidate CloudFront cache"
  value       = var.enable_cloudfront ? "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.main[0].id} --paths '/*'" : "CloudFront not enabled"
}

output "view_logs_command" {
  description = "Command to view ECS logs"
  value       = "aws logs tail /ecs/${var.project_name} --follow --region ${var.aws_region}"
}

# -----------------------------------------------------------------------------
# Auto Scaling Info
# -----------------------------------------------------------------------------

output "autoscaling_info" {
  description = "Auto scaling configuration summary"
  value       = <<-EOT
    Min tasks: ${var.min_capacity}
    Max tasks: ${var.max_capacity}
    CPU target: ${var.cpu_target_value}%
    Memory target: ${var.memory_target_value}%

    Scale out cooldown: ${var.scale_out_cooldown}s
    Scale in cooldown: ${var.scale_in_cooldown}s
  EOT
}

# -----------------------------------------------------------------------------
# Cost Estimate
# -----------------------------------------------------------------------------

output "estimated_monthly_cost" {
  description = "Rough estimate of monthly costs (USD)"
  value       = <<-EOT
    Estimated Monthly Costs (approximate):
    ─────────────────────────────────────
    NAT Gateway:        ~$32
    ALB:                ~$16
    Fargate (min):      ~$${var.min_capacity * 20} (${var.min_capacity} tasks × ~$20)
    CloudFront:         ~$${var.enable_cloudfront ? "Variable (pay per request)" : "N/A"}
    WAF:                ~$${var.enable_waf ? "5 + per request" : "N/A"}
    Route 53:           ~$0.50
    CloudWatch Logs:    ~$1-5
    ─────────────────────────────────────
    Base Total:         ~$${50 + (var.min_capacity * 20)}/month

    Note: Actual costs depend on traffic and scaling.
  EOT
}
