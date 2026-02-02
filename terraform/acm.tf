# =============================================================================
# ACM (AWS Certificate Manager) - SSL/TLS Certificates
# =============================================================================
# ACM provides FREE SSL certificates for HTTPS.
# Certificates auto-renew, so you never have to worry about expiration.
#
# IMPORTANT: For ALB, the certificate must be in the SAME REGION as the ALB.
# (For CloudFront, it must be in us-east-1)

# -----------------------------------------------------------------------------
# SSL Certificate
# -----------------------------------------------------------------------------
# Request a certificate for your API subdomain.
# DNS validation is automatic if your domain is in Route 53.

resource "aws_acm_certificate" "main" {
  count = var.create_dns_records ? 1 : 0

  domain_name       = "${var.api_subdomain}.${var.domain_name}"  # e.g., api.myapp.com
  validation_method = "DNS"  # Validate via DNS records (automatic with Route 53)

  # Create new certificate before destroying old one (prevents downtime)
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-cert"
  }
}

# -----------------------------------------------------------------------------
# DNS Validation Records
# -----------------------------------------------------------------------------
# ACM needs to verify you own the domain.
# These records prove ownership and are created automatically.

resource "aws_route53_record" "cert_validation" {
  for_each = var.create_dns_records ? {
    for dvo in aws_acm_certificate.main[0].domain_validation_options : dvo.domain_name => {
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

# -----------------------------------------------------------------------------
# Certificate Validation
# -----------------------------------------------------------------------------
# Wait for the certificate to be validated before using it.
# Validation usually takes 2-5 minutes.

resource "aws_acm_certificate_validation" "main" {
  count = var.create_dns_records ? 1 : 0

  certificate_arn         = aws_acm_certificate.main[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  # This can take a few minutes
  timeouts {
    create = "10m"
  }
}
