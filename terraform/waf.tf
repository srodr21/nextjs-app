# =============================================================================
# WAF (Web Application Firewall)
# =============================================================================
# WAF protects your application from common web exploits.
# It filters malicious traffic before it reaches your application.
#
# This configuration includes:
# - Rate limiting (prevent DDoS)
# - AWS Managed Rules for common threats
# - SQL injection protection
# - Cross-site scripting (XSS) protection

resource "aws_wafv2_web_acl" "main" {
  count = var.enable_waf ? 1 : 0

  name        = "${var.project_name}-waf"
  description = "WAF for ${var.project_name}"
  scope       = "CLOUDFRONT"  # Use REGIONAL for ALB without CloudFront

  # Must be created in us-east-1 for CloudFront
  provider = aws.us_east_1

  default_action {
    allow {}  # Allow traffic by default, block specific threats
  }

  # -----------------------------------------------------------------------------
  # Rule 1: Rate Limiting
  # -----------------------------------------------------------------------------
  # Prevents DDoS attacks by limiting requests per IP

  rule {
    name     = "rate-limit"
    priority = 1

    override_action {
      none {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit  # Requests per 5 minutes
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  # -----------------------------------------------------------------------------
  # Rule 2: AWS Managed Rules - Common Rule Set
  # -----------------------------------------------------------------------------
  # Protects against common web exploits (OWASP Top 10)

  rule {
    name     = "aws-common-rules"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        # Exclude rules that might cause false positives for Next.js
        rule_action_override {
          action_to_use {
            count {}  # Count instead of block for monitoring
          }
          name = "SizeRestrictions_BODY"  # Next.js API routes might have large bodies
        }

        rule_action_override {
          action_to_use {
            count {}
          }
          name = "GenericRFI_BODY"  # May trigger on legitimate API calls
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  # -----------------------------------------------------------------------------
  # Rule 3: AWS Managed Rules - Known Bad Inputs
  # -----------------------------------------------------------------------------
  # Blocks requests with known bad patterns

  rule {
    name     = "aws-known-bad-inputs"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  # -----------------------------------------------------------------------------
  # Rule 4: AWS Managed Rules - SQL Injection
  # -----------------------------------------------------------------------------
  # Protects against SQL injection attacks

  rule {
    name     = "aws-sql-injection"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-sqli"
      sampled_requests_enabled   = true
    }
  }

  # -----------------------------------------------------------------------------
  # Rule 5: Block Bad Bots
  # -----------------------------------------------------------------------------
  # Blocks known bad bots and scrapers

  rule {
    name     = "aws-bad-bots"
    priority = 5

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"

        managed_rule_group_configs {
          aws_managed_rules_bot_control_rule_set {
            inspection_level = "COMMON"  # Use TARGETED for more aggressive bot detection
          }
        }

        # Allow good bots (search engines, etc.)
        rule_action_override {
          action_to_use {
            allow {}
          }
          name = "CategoryVerifiedSearchEngine"
        }

        rule_action_override {
          action_to_use {
            allow {}
          }
          name = "CategoryVerifiedSocialMedia"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-bots"
      sampled_requests_enabled   = true
    }
  }

  # -----------------------------------------------------------------------------
  # Rule 6: Geographic Blocking (Optional)
  # -----------------------------------------------------------------------------
  # Uncomment to block specific countries
  #
  # rule {
  #   name     = "geo-block"
  #   priority = 6
  #
  #   action {
  #     block {}
  #   }
  #
  #   statement {
  #     geo_match_statement {
  #       country_codes = ["XX", "YY"]  # Add country codes to block
  #     }
  #   }
  #
  #   visibility_config {
  #     cloudwatch_metrics_enabled = true
  #     metric_name                = "${var.project_name}-geo-block"
  #     sampled_requests_enabled   = true
  #   }
  # }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${var.project_name}-waf"
  }
}

# -----------------------------------------------------------------------------
# WAF Logging (Optional)
# -----------------------------------------------------------------------------
# Log WAF activity to CloudWatch for analysis

resource "aws_cloudwatch_log_group" "waf" {
  count = var.enable_waf ? 1 : 0

  # WAF log group name must start with aws-waf-logs-
  name              = "aws-waf-logs-${var.project_name}"
  retention_in_days = var.log_retention_days

  provider = aws.us_east_1

  tags = {
    Name = "${var.project_name}-waf-logs"
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "main" {
  count = var.enable_waf ? 1 : 0

  provider = aws.us_east_1

  log_destination_configs = [aws_cloudwatch_log_group.waf[0].arn]
  resource_arn            = aws_wafv2_web_acl.main[0].arn

  # Optionally filter what gets logged
  # logging_filter {
  #   default_behavior = "DROP"
  #
  #   filter {
  #     behavior = "KEEP"
  #     condition {
  #       action_condition {
  #         action = "BLOCK"
  #       }
  #     }
  #     requirement = "MEETS_ANY"
  #   }
  # }
}
