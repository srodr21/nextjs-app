# =============================================================================
# Input Variables
# =============================================================================
# These variables allow customization of the infrastructure.
# Default values are provided but can be overridden in terraform.tfvars

# -----------------------------------------------------------------------------
# General Settings
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "nextjs-app"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

# -----------------------------------------------------------------------------
# Domain and SSL Settings
# -----------------------------------------------------------------------------

variable "domain_name" {
  description = "Root domain name (e.g., myapp.com)"
  type        = string
  default     = ""
}

variable "api_subdomain" {
  description = "Subdomain for the app (e.g., 'www' for www.myapp.com, or '' for apex domain)"
  type        = string
  default     = ""  # Empty = apex domain (myapp.com)
}

variable "create_dns_records" {
  description = "Whether to create Route53 DNS records and ACM certificate"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# CloudFront CDN Settings
# -----------------------------------------------------------------------------

variable "enable_cloudfront" {
  description = "Whether to create CloudFront distribution for CDN"
  type        = bool
  default     = true
}

variable "cloudfront_price_class" {
  description = "CloudFront price class (PriceClass_100 = US/EU, PriceClass_200 = +Asia, PriceClass_All = Global)"
  type        = string
  default     = "PriceClass_200"
}

variable "cloudfront_min_ttl" {
  description = "Minimum TTL for CloudFront cache (seconds)"
  type        = number
  default     = 0
}

variable "cloudfront_default_ttl" {
  description = "Default TTL for CloudFront cache (seconds)"
  type        = number
  default     = 86400  # 1 day
}

variable "cloudfront_max_ttl" {
  description = "Maximum TTL for CloudFront cache (seconds)"
  type        = number
  default     = 31536000  # 1 year
}

# -----------------------------------------------------------------------------
# WAF Settings
# -----------------------------------------------------------------------------

variable "enable_waf" {
  description = "Whether to enable WAF (Web Application Firewall)"
  type        = bool
  default     = true
}

variable "waf_rate_limit" {
  description = "Maximum requests per 5 minutes from a single IP"
  type        = number
  default     = 2000
}

# -----------------------------------------------------------------------------
# Container Settings
# -----------------------------------------------------------------------------

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 3000  # Next.js default port
}

variable "container_cpu" {
  description = "CPU units for the container (256 = 0.25 vCPU)"
  type        = number
  default     = 512  # 0.5 vCPU for Next.js
}

variable "container_memory" {
  description = "Memory for the container in MB"
  type        = number
  default     = 1024  # 1 GB for Next.js
}

# -----------------------------------------------------------------------------
# Auto-scaling Settings
# -----------------------------------------------------------------------------

variable "min_capacity" {
  description = "Minimum number of tasks"
  type        = number
  default     = 2  # At least 2 for high availability
}

variable "max_capacity" {
  description = "Maximum number of tasks"
  type        = number
  default     = 10
}

variable "cpu_target_value" {
  description = "Target CPU utilization percentage for auto-scaling"
  type        = number
  default     = 70
}

variable "memory_target_value" {
  description = "Target memory utilization percentage for auto-scaling"
  type        = number
  default     = 80
}

variable "scale_in_cooldown" {
  description = "Cooldown period (seconds) before scaling in"
  type        = number
  default     = 300
}

variable "scale_out_cooldown" {
  description = "Cooldown period (seconds) before scaling out"
  type        = number
  default     = 60
}

# -----------------------------------------------------------------------------
# Health Check Settings
# -----------------------------------------------------------------------------

variable "health_check_path" {
  description = "Path for ALB health checks"
  type        = string
  default     = "/api/health"  # Create this endpoint in your Next.js app
}

variable "health_check_matcher" {
  description = "HTTP status codes to consider healthy"
  type        = string
  default     = "200"
}

variable "health_check_interval" {
  description = "Seconds between health checks"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Seconds to wait for health check response"
  type        = number
  default     = 10
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive successful health checks"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failed health checks"
  type        = number
  default     = 3
}

variable "container_start_period" {
  description = "Grace period (seconds) for container to start before health checks begin"
  type        = number
  default     = 60  # Next.js can take time to start
}

# -----------------------------------------------------------------------------
# Logging Settings
# -----------------------------------------------------------------------------

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30  # Longer retention for production
}

# -----------------------------------------------------------------------------
# Next.js Specific Settings
# -----------------------------------------------------------------------------

variable "nextjs_sharp_memory" {
  description = "Enable sharp memory optimization for Next.js Image"
  type        = bool
  default     = true
}

variable "node_env" {
  description = "Node environment (development, production)"
  type        = string
  default     = "production"
}
