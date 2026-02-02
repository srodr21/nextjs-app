# =============================================================================
# VPC Configuration
# =============================================================================
# Uses the official AWS VPC module to create:
# - VPC with DNS support
# - Public subnets (for ALB)
# - Private subnets (for ECS tasks)
# - Internet Gateway
# - NAT Gateway (for private subnet internet access)
# - Route tables

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.0"

  # VPC Basic Settings
  name = "${var.project_name}-vpc"
  cidr = "10.0.0.0/16"  # 65,536 IP addresses

  # Availability Zones - use 2 for high availability
  azs = ["${var.aws_region}a", "${var.aws_region}b"]

  # Subnet CIDR blocks
  # Public subnets: For ALB and NAT Gateway (internet accessible)
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]  # 256 IPs each

  # Private subnets: For ECS tasks (not directly internet accessible)
  private_subnets = ["10.0.10.0/24", "10.0.20.0/24"]  # 256 IPs each

  # NAT Gateway configuration
  # NAT allows private subnets to reach internet (for pulling Docker images)
  enable_nat_gateway = true
  single_nat_gateway = true  # Use one NAT Gateway to save costs (~$32/month)

  # DNS settings (required for service discovery and ECR access)
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags for subnets (useful for identifying resources)
  public_subnet_tags = {
    Type = "Public"
  }

  private_subnet_tags = {
    Type = "Private"
  }

  tags = {
    Name = "${var.project_name}-vpc"
  }
}
