# =============================================================================
# CloudFront CDN Configuration
# =============================================================================
# CloudFront is AWS's CDN (Content Delivery Network).
# It caches your content at edge locations worldwide for faster delivery.
#
# Benefits for Next.js:
# - Caches static assets (_next/static/*)
# - Reduces load on your ECS tasks
# - Global distribution for lower latency
# - DDoS protection via AWS Shield Standard (free)
# - HTTPS with custom domain

# -----------------------------------------------------------------------------
# CloudFront Origin Access Control
# -----------------------------------------------------------------------------
# Not needed for ALB origin, but useful for S3 origins

# -----------------------------------------------------------------------------
# CloudFront Cache Policy for Next.js
# -----------------------------------------------------------------------------
# Custom cache policy optimized for Next.js applications

resource "aws_cloudfront_cache_policy" "nextjs" {
  count = var.enable_cloudfront ? 1 : 0

  name        = "${var.project_name}-nextjs-cache-policy"
  comment     = "Cache policy optimized for Next.js"
  default_ttl = var.cloudfront_default_ttl
  max_ttl     = var.cloudfront_max_ttl
  min_ttl     = var.cloudfront_min_ttl

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"  # Don't cache based on cookies for static
    }

    headers_config {
      header_behavior = "none"  # Don't cache based on headers for static
    }

    query_strings_config {
      query_string_behavior = "none"  # Don't cache based on query strings for static
    }

    enable_accept_encoding_brotli = true  # Enable Brotli compression
    enable_accept_encoding_gzip   = true  # Enable Gzip compression
  }
}

# -----------------------------------------------------------------------------
# CloudFront Cache Policy for Dynamic Content
# -----------------------------------------------------------------------------
# For API routes and dynamic pages - minimal caching, forward everything

resource "aws_cloudfront_cache_policy" "dynamic" {
  count = var.enable_cloudfront ? 1 : 0

  name        = "${var.project_name}-dynamic-cache-policy"
  comment     = "Cache policy for dynamic Next.js content"
  default_ttl = 0
  max_ttl     = 0
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "all"  # Forward all cookies
    }

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Host", "Origin", "Accept", "Accept-Language", "Authorization"]
      }
    }

    query_strings_config {
      query_string_behavior = "all"  # Forward all query strings
    }

    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

# -----------------------------------------------------------------------------
# CloudFront Origin Request Policy
# -----------------------------------------------------------------------------
# Controls what CloudFront sends to the origin (ALB)

resource "aws_cloudfront_origin_request_policy" "nextjs" {
  count = var.enable_cloudfront ? 1 : 0

  name    = "${var.project_name}-origin-request-policy"
  comment = "Origin request policy for Next.js"

  cookies_config {
    cookie_behavior = "all"  # Forward all cookies to origin
  }

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = [
        "Host",
        "Origin",
        "Accept",
        "Accept-Language",
        "Accept-Encoding",
        "Referer",
        "CloudFront-Is-Desktop-Viewer",
        "CloudFront-Is-Mobile-Viewer",
        "CloudFront-Is-Tablet-Viewer",
        "CloudFront-Viewer-Country"
      ]
    }
  }

  query_strings_config {
    query_string_behavior = "all"  # Forward all query strings
  }
}

# -----------------------------------------------------------------------------
# CloudFront Distribution
# -----------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "main" {
  count = var.enable_cloudfront ? 1 : 0

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} CloudFront Distribution"
  default_root_object = ""  # Next.js handles routing
  price_class         = var.cloudfront_price_class
  http_version        = "http2and3"  # Enable HTTP/3 for better performance

  # Custom domain aliases (only if DNS is configured)
  aliases = var.create_dns_records ? (
    var.api_subdomain != "" ? ["${var.api_subdomain}.${var.domain_name}"] : [var.domain_name]
  ) : []

  # Origin: ALB
  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = "alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = var.create_dns_records ? "https-only" : "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      origin_read_timeout    = 60
    }

    # Custom headers to identify CloudFront traffic
    custom_header {
      name  = "X-Custom-Header"
      value = "CloudFront"
    }
  }

  # Default behavior (dynamic content - API routes, SSR pages)
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "alb"

    # Use managed caching disabled policy for dynamic content
    cache_policy_id          = aws_cloudfront_cache_policy.dynamic[0].id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.nextjs[0].id

    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # Function associations (optional - for edge functions)
    # function_association {
    #   event_type   = "viewer-request"
    #   function_arn = aws_cloudfront_function.example.arn
    # }
  }

  # Cache behavior for Next.js static assets
  ordered_cache_behavior {
    path_pattern     = "/_next/static/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "alb"

    cache_policy_id          = aws_cloudfront_cache_policy.nextjs[0].id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.nextjs[0].id

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  # Cache behavior for static files (images, fonts, etc.)
  ordered_cache_behavior {
    path_pattern     = "/static/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "alb"

    cache_policy_id          = aws_cloudfront_cache_policy.nextjs[0].id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.nextjs[0].id

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  # Cache behavior for public files (favicon, robots.txt, etc.)
  ordered_cache_behavior {
    path_pattern     = "/*.ico"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "alb"

    cache_policy_id = aws_cloudfront_cache_policy.nextjs[0].id

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  ordered_cache_behavior {
    path_pattern     = "/*.txt"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "alb"

    cache_policy_id = aws_cloudfront_cache_policy.nextjs[0].id

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  # Cache behavior for Next.js image optimization
  ordered_cache_behavior {
    path_pattern     = "/_next/image*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "alb"

    cache_policy_id          = aws_cloudfront_cache_policy.nextjs[0].id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.nextjs[0].id

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  # SSL Certificate
  viewer_certificate {
    # Use ACM certificate if custom domain, otherwise CloudFront default
    acm_certificate_arn            = var.create_dns_records ? aws_acm_certificate.cloudfront[0].arn : null
    cloudfront_default_certificate = var.create_dns_records ? false : true
    ssl_support_method             = var.create_dns_records ? "sni-only" : null
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  # Geo restrictions (none by default)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # WAF association
  web_acl_id = var.enable_waf ? aws_wafv2_web_acl.main[0].arn : null

  # Wait for certificate validation
  depends_on = [
    aws_acm_certificate_validation.cloudfront
  ]

  tags = {
    Name = "${var.project_name}-cloudfront"
  }
}

# -----------------------------------------------------------------------------
# ACM Certificate for CloudFront (must be in us-east-1)
# -----------------------------------------------------------------------------
# CloudFront requires certificates in us-east-1 region

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

resource "aws_acm_certificate" "cloudfront" {
  count    = var.create_dns_records && var.enable_cloudfront ? 1 : 0
  provider = aws.us_east_1

  domain_name       = var.api_subdomain != "" ? "${var.api_subdomain}.${var.domain_name}" : var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-cloudfront-cert"
  }
}

# DNS validation for CloudFront certificate
resource "aws_route53_record" "cloudfront_cert_validation" {
  for_each = var.create_dns_records && var.enable_cloudfront ? {
    for dvo in aws_acm_certificate.cloudfront[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main[0].zone_id
}

resource "aws_acm_certificate_validation" "cloudfront" {
  count    = var.create_dns_records && var.enable_cloudfront ? 1 : 0
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.cloudfront[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_cert_validation : record.fqdn]

  timeouts {
    create = "10m"
  }
}

# -----------------------------------------------------------------------------
# Route 53 Record for CloudFront
# -----------------------------------------------------------------------------
# Point domain to CloudFront instead of ALB when CloudFront is enabled

resource "aws_route53_record" "cloudfront" {
  count = var.create_dns_records && var.enable_cloudfront ? 1 : 0

  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = var.api_subdomain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main[0].domain_name
    zone_id                = aws_cloudfront_distribution.main[0].hosted_zone_id
    evaluate_target_health = false
  }
}
