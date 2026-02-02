# =============================================================================
# ECR (Elastic Container Registry)
# =============================================================================
# ECR is a private Docker registry to store your container images.
# It's like Docker Hub, but private to your AWS account.

resource "aws_ecr_repository" "main" {
  name = var.project_name

  # MUTABLE allows overwriting tags (e.g., pushing new :latest)
  # IMMUTABLE prevents tag overwrites (safer for production)
  image_tag_mutability = "MUTABLE"

  # Scan images for vulnerabilities when pushed
  image_scanning_configuration {
    scan_on_push = true
  }

  # Force delete repository even if it contains images
  # Set to false in production to prevent accidental deletion
  force_delete = true

  tags = {
    Name = "${var.project_name}-ecr"
  }
}

# -----------------------------------------------------------------------------
# ECR Lifecycle Policy
# -----------------------------------------------------------------------------
# Automatically clean up old images to save storage costs.
# Keeps only the last 10 images.

resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
