# =============================================================================
# Terraform Variables - Production Configuration
# =============================================================================
# This file contains your specific configuration values.
# Modify these values according to your project needs.
#
# WARNING: Do NOT commit this file if it contains secrets!
# Add to .gitignore if you add sensitive values later.

# -----------------------------------------------------------------------------
# General Settings
# -----------------------------------------------------------------------------

aws_region   = "ap-southeast-1"    # Singapore region
project_name = "nextjs-app"        # Used for naming all resources
environment  = "prod"              # dev, staging, or prod

# -----------------------------------------------------------------------------
# Container Settings (Production-grade for Next.js)
# -----------------------------------------------------------------------------

container_port   = 3000   # Next.js default port
container_cpu    = 512    # 0.5 vCPU (increase for heavy apps)
container_memory = 1024   # 1 GB RAM (increase for heavy apps)

# -----------------------------------------------------------------------------
# Auto Scaling Settings
# -----------------------------------------------------------------------------

min_capacity       = 2     # Minimum 2 tasks for high availability
max_capacity       = 10    # Maximum tasks during traffic spikes
cpu_target_value   = 70    # Scale out when CPU > 70%
memory_target_value = 80   # Scale out when memory > 80%
scale_in_cooldown  = 300   # Wait 5 min before scaling in (prevents flapping)
scale_out_cooldown = 60    # Wait 1 min before scaling out (react quickly)

# -----------------------------------------------------------------------------
# Health Check Settings (Tuned for Next.js)
# -----------------------------------------------------------------------------

health_check_path               = "/api/health"  # Create this endpoint in your app
health_check_matcher            = "200"
health_check_interval           = 30
health_check_timeout            = 10
health_check_healthy_threshold  = 2
health_check_unhealthy_threshold = 3
container_start_period          = 60   # Grace period for Next.js startup

# -----------------------------------------------------------------------------
# CloudFront CDN Settings
# -----------------------------------------------------------------------------

enable_cloudfront      = true
cloudfront_price_class = "PriceClass_200"  # US, EU, Asia (most users)
# Options:
#   PriceClass_100 = US, Canada, Europe (cheapest)
#   PriceClass_200 = Above + Asia, Middle East, Africa
#   PriceClass_All = All edge locations (most expensive)

cloudfront_min_ttl     = 0        # Don't cache by default
cloudfront_default_ttl = 86400    # 1 day for static assets
cloudfront_max_ttl     = 31536000 # 1 year max

# -----------------------------------------------------------------------------
# WAF (Web Application Firewall) Settings
# -----------------------------------------------------------------------------

enable_waf     = true
waf_rate_limit = 2000  # Max 2000 requests per 5 minutes per IP

# -----------------------------------------------------------------------------
# Logging Settings
# -----------------------------------------------------------------------------

log_retention_days = 30  # Keep logs for 30 days

# -----------------------------------------------------------------------------
# Next.js Specific Settings
# -----------------------------------------------------------------------------

nextjs_sharp_memory = true   # Enable sharp memory optimization
node_env            = "production"

# -----------------------------------------------------------------------------
# Domain Settings (REQUIRED for HTTPS - uncomment after buying domain)
# -----------------------------------------------------------------------------
# 1. First, buy a domain in Route 53 (AWS Console)
# 2. Then uncomment these lines and run terraform apply

# create_dns_records = true
# domain_name        = "yourdomain.com"    # Your registered domain
# api_subdomain      = ""                  # Empty = apex domain (yourdomain.com)
#                                          # Use "www" for www.yourdomain.com
#                                          # Use "app" for app.yourdomain.com
