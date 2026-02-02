# =============================================================================
# Terraform Configuration
# =============================================================================
# This file configures Terraform and the AWS provider.
# It specifies which version of Terraform and AWS provider to use.

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# =============================================================================
# AWS Provider Configuration
# =============================================================================
# Configures the AWS provider with the region and default tags.
# All resources created will automatically inherit these tags.

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
