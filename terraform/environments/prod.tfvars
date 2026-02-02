# =============================================================================
# Production Environment Configuration
# =============================================================================
# Deploy with: terraform apply -var-file=environments/prod.tfvars

aws_region   = "ap-southeast-1"
project_name = "nextjs-app-prod" # Include env in name for resource separation
environment  = "prod"

# -----------------------------------------------------------------------------
# Container Settings (Production-grade)
# -----------------------------------------------------------------------------
container_port   = 3000
container_cpu    = 512  # 0.5 vCPU
container_memory = 1024 # 1 GB

# -----------------------------------------------------------------------------
# Auto Scaling (Production capacity)
# -----------------------------------------------------------------------------
min_capacity        = 2  # Always 2 for high availability
max_capacity        = 10 # Scale up to 10 during traffic spikes
cpu_target_value    = 70
memory_target_value = 80
scale_in_cooldown   = 300 # 5 min cooldown
scale_out_cooldown  = 60  # 1 min for quick response

# -----------------------------------------------------------------------------
# Production Features - Enable all
# -----------------------------------------------------------------------------
enable_cloudfront      = true
cloudfront_price_class = "PriceClass_200" # US, EU, Asia
cloudfront_min_ttl     = 0
cloudfront_default_ttl = 86400    # 1 day
cloudfront_max_ttl     = 31536000 # 1 year

enable_waf     = true
waf_rate_limit = 2000

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
log_retention_days = 30 # Longer retention for prod

# -----------------------------------------------------------------------------
# Next.js Settings
# -----------------------------------------------------------------------------
nextjs_sharp_memory = true
node_env            = "production"

# -----------------------------------------------------------------------------
# Domain (Enable for production)
# -----------------------------------------------------------------------------
# 1. First, buy a domain in Route 53 (AWS Console)
# 2. Then uncomment these lines and run terraform apply

# create_dns_records = true
# domain_name        = "yourdomain.com"   # <-- CHANGE THIS
# api_subdomain      = ""                 # Empty = apex domain
