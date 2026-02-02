# =============================================================================
# Route 53 DNS Configuration
# =============================================================================
# Route 53 is AWS's DNS service. It translates domain names to IP addresses.
# This file creates DNS records to point your domain to CloudFront or ALB.
#
# PREREQUISITE: You must have a domain registered in Route 53 first!
# Buy a domain in AWS Console: Route 53 → Registered domains → Register domain

# -----------------------------------------------------------------------------
# Hosted Zone (Data Source)
# -----------------------------------------------------------------------------
# Look up the existing hosted zone for your domain.
# The hosted zone is automatically created when you register a domain in Route 53.

data "aws_route53_zone" "main" {
  count = var.create_dns_records ? 1 : 0

  name         = var.domain_name  # e.g., "myapp.com"
  private_zone = false
}

# -----------------------------------------------------------------------------
# DNS Record for API/App
# -----------------------------------------------------------------------------
# Creates an ALIAS record pointing your subdomain to CloudFront or ALB.
# ALIAS records are free and work with AWS resources.
#
# Note: When CloudFront is enabled, the DNS record is created in cloudfront.tf
# This record is only created when CloudFront is disabled.

resource "aws_route53_record" "api" {
  count = var.create_dns_records && !var.enable_cloudfront ? 1 : 0

  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = var.api_subdomain  # e.g., "www" for www.myapp.com
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true  # Route 53 health checks
  }
}

# -----------------------------------------------------------------------------
# Apex Domain Record (Optional)
# -----------------------------------------------------------------------------
# If you want the apex domain (myapp.com without www) to also work,
# you can either:
# 1. Redirect apex to www (recommended)
# 2. Point apex directly to the same resource

# Option 1: Redirect apex to www using S3 (simple but requires S3 bucket)
# Option 2: Point apex to same resource as subdomain

# resource "aws_route53_record" "apex" {
#   count = var.create_dns_records && var.api_subdomain != "" ? 1 : 0
#
#   zone_id = data.aws_route53_zone.main[0].zone_id
#   name    = ""  # Empty = apex domain
#   type    = "A"
#
#   alias {
#     name                   = var.enable_cloudfront ? aws_cloudfront_distribution.main[0].domain_name : aws_lb.main.dns_name
#     zone_id                = var.enable_cloudfront ? aws_cloudfront_distribution.main[0].hosted_zone_id : aws_lb.main.zone_id
#     evaluate_target_health = !var.enable_cloudfront
#   }
# }
