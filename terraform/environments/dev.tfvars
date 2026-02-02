# =============================================================================
# Development Environment Configuration
# =============================================================================
# Deploy with: terraform apply -var-file=environments/dev.tfvars

aws_region   = "ap-southeast-1"
project_name = "nextjs-app-dev" # Include env in name for resource separation
environment  = "dev"

# -----------------------------------------------------------------------------
# Container Settings (Smaller for dev)
# -----------------------------------------------------------------------------
container_port   = 3000
container_cpu    = 256 # 0.25 vCPU (minimum)
container_memory = 512 # 512 MB (minimum)

# -----------------------------------------------------------------------------
# Auto Scaling (Minimal for dev)
# -----------------------------------------------------------------------------
min_capacity        = 1 # Just 1 task for dev
max_capacity        = 2 # Max 2 during testing
cpu_target_value    = 70
memory_target_value = 80
scale_in_cooldown   = 300
scale_out_cooldown  = 60

# -----------------------------------------------------------------------------
# Cost Savings - Disable expensive features for dev
# -----------------------------------------------------------------------------
enable_cloudfront = false # No CDN for dev
enable_waf        = false # No WAF for dev

# -----------------------------------------------------------------------------
# Health Check
# -----------------------------------------------------------------------------
health_check_path                = "/api/health"
health_check_matcher             = "200"
health_check_interval            = 30
health_check_timeout             = 10
health_check_healthy_threshold   = 2
health_check_unhealthy_threshold = 3
container_start_period           = 60

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
log_retention_days = 7 # Short retention for dev

# -----------------------------------------------------------------------------
# Next.js Settings
# -----------------------------------------------------------------------------
nextjs_sharp_memory = true
node_env            = "production" # Still use production build in dev ECS

# -----------------------------------------------------------------------------
# Domain (Optional - usually skip for dev, use ALB URL directly)
# -----------------------------------------------------------------------------
create_dns_records = false
domain_name        = ""
api_subdomain      = ""
