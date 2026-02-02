# =============================================================================
# Terraform Backend Configuration
# =============================================================================
# Uncomment this to use S3 for remote state storage.
# This allows team collaboration and keeps state secure.
#
# IMPORTANT: Create the S3 bucket manually first, or use a separate
# Terraform config to bootstrap it.
#
# Benefits of remote state:
# - Team collaboration (multiple people can run terraform)
# - State locking prevents concurrent modifications
# - State is backed up and versioned
# - Separate state per environment

# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"   # Create this bucket first
#     key            = "nextjs-app/terraform.tfstate"  # Path in bucket
#     region         = "ap-southeast-1"
#     encrypt        = true
#     dynamodb_table = "terraform-locks"               # Optional: for state locking
#   }
# }

# =============================================================================
# Alternative: Terraform Workspaces
# =============================================================================
# Instead of separate state files, you can use workspaces:
#
# terraform workspace new dev
# terraform workspace new prod
#
# terraform workspace select dev
# terraform apply -var-file=environments/dev.tfvars
#
# terraform workspace select prod
# terraform apply -var-file=environments/prod.tfvars
#
# With S3 backend, each workspace gets its own state file:
#   s3://bucket/env:/dev/terraform.tfstate
#   s3://bucket/env:/prod/terraform.tfstate
