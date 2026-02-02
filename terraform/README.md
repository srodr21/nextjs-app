# Production-Grade Next.js Infrastructure on AWS

This Terraform configuration deploys a **production-ready Next.js application** to AWS with enterprise-grade features.

## Architecture

```
                                   ┌─────────────────┐
                                   │   Route 53      │
                                   │   (DNS)         │
                                   └────────┬────────┘
                                            │
                                   ┌────────▼────────┐
                                   │   CloudFront    │
                                   │   (CDN + Cache) │
                                   │   + WAF         │
                                   └────────┬────────┘
                                            │
┌───────────────────────────────────────────┼───────────────────────────────────────────┐
│                                  VPC      │                                           │
│                                           │                                           │
│   ┌───────────────────────────────────────┼───────────────────────────────────────┐   │
│   │              PUBLIC SUBNETS           │                                       │   │
│   │                              ┌────────▼────────┐                              │   │
│   │          AZ-a                │      ALB        │               AZ-b           │   │
│   │                              │  (Load Balancer)│                              │   │
│   │                              └────────┬────────┘                              │   │
│   │                                       │                                       │   │
│   │   ┌─────────────┐                     │                    ┌─────────────┐    │   │
│   │   │ NAT Gateway │                     │                    │             │    │   │
│   │   └──────┬──────┘                     │                    └─────────────┘    │   │
│   └──────────┼────────────────────────────┼───────────────────────────────────────┘   │
│              │                            │                                           │
│   ┌──────────┼────────────────────────────┼───────────────────────────────────────┐   │
│   │          │     PRIVATE SUBNETS        │                                       │   │
│   │          │                   ┌────────┴────────┐                              │   │
│   │          │                   │   Auto Scaling  │                              │   │
│   │          │                   │   ECS Service   │                              │   │
│   │          │                   └─────────────────┘                              │   │
│   │          │           ┌───────────┬───────────┬───────────┐                    │   │
│   │          │           │           │           │           │                    │   │
│   │          ▼           ▼           ▼           ▼           ▼                    │   │
│   │      (Internet)   [Task 1]   [Task 2]   [Task 3]   [Task N]                   │   │
│   │                   (Next.js) (Next.js)  (Next.js)  (Next.js)                   │   │
│   └───────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                       │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

## Features

| Feature | Description |
|---------|-------------|
| **CloudFront CDN** | Global edge caching, HTTP/3, Brotli compression |
| **WAF** | SQL injection, XSS, bot protection, rate limiting |
| **Auto Scaling** | 2-10 tasks based on CPU/memory/requests |
| **High Availability** | Multi-AZ deployment, health checks, auto-recovery |
| **HTTPS** | Free ACM certificates, TLS 1.3 |
| **Container Insights** | Detailed monitoring and logging |
| **Deployment Safety** | Circuit breaker, automatic rollback |

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **Docker** for building and pushing images
4. **Domain** (optional) registered in Route 53 for HTTPS

## Quick Start

### 1. Configure Variables

Edit `terraform.tfvars`:

```hcl
project_name = "my-nextjs-app"
aws_region   = "ap-southeast-1"

# For HTTPS with custom domain (after buying domain):
# create_dns_records = true
# domain_name        = "myapp.com"
# api_subdomain      = "www"
```

### 2. Initialize & Deploy

```bash
cd terraform
terraform init
terraform plan    # Review changes
terraform apply   # Deploy (confirm with 'yes')
```

### 3. Create Health Check Endpoint

Add this to your Next.js app at `pages/api/health.js` or `app/api/health/route.ts`:

```typescript
// app/api/health/route.ts (App Router)
export async function GET() {
  return Response.json({ status: 'healthy', timestamp: new Date().toISOString() })
}
```

### 4. Build & Push Docker Image

```bash
# Get ECR login
aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin <ECR_URL>

# Build and push
docker build -t my-nextjs-app .
docker tag my-nextjs-app:latest <ECR_URL>:latest
docker push <ECR_URL>:latest

# Deploy new version
aws ecs update-service --cluster my-nextjs-app-cluster --service my-nextjs-app-service --force-new-deployment
```

### 5. Invalidate CloudFront Cache (after deployments)

```bash
aws cloudfront create-invalidation --distribution-id <DIST_ID> --paths "/*"
```

## File Structure

```
terraform/
├── main.tf              # Provider configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── backend.tf           # Remote state configuration (optional)
├── terraform.tfvars     # Default configuration (legacy)
├── environments/        # Environment-specific configs
│   ├── dev.tfvars       # Development settings
│   └── prod.tfvars      # Production settings
├── vpc.tf               # VPC, subnets, NAT
├── security-groups.tf   # Firewall rules
├── ecr.tf               # Docker repository
├── iam.tf               # IAM roles/policies
├── alb.tf               # Load balancer
├── ecs.tf               # ECS cluster/service
├── autoscaling.tf       # Auto scaling policies
├── cloudfront.tf        # CDN configuration
├── waf.tf               # Web Application Firewall
├── route53.tf           # DNS records
└── acm.tf               # SSL certificates
```

## Multi-Environment Deployment

This Terraform configuration supports separate dev and prod environments using different tfvars files.

### Deploy to Development

```bash
cd terraform
terraform init
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars
```

### Deploy to Production

```bash
terraform plan -var-file=environments/prod.tfvars
terraform apply -var-file=environments/prod.tfvars
```

### Environment Differences

| Feature | Dev | Prod |
|---------|-----|------|
| Min Tasks | 1 | 2 |
| Max Tasks | 2 | 10 |
| Container CPU | 256 (0.25 vCPU) | 512 (0.5 vCPU) |
| Container Memory | 512 MB | 1024 MB |
| CloudFront CDN | Disabled | Enabled |
| WAF | Disabled | Enabled |
| Log Retention | 7 days | 30 days |
| Custom Domain | No (use ALB URL) | Yes (optional) |

### Separate State Files

To keep dev and prod state completely separate:

**Option 1: Local state files**
```bash
# Dev
terraform apply -var-file=environments/dev.tfvars

# Prod (different state file)
terraform apply -var-file=environments/prod.tfvars -state=prod.tfstate
```

**Option 2: Terraform Workspaces**
```bash
terraform workspace new dev
terraform workspace new prod

terraform workspace select dev
terraform apply -var-file=environments/dev.tfvars

terraform workspace select prod
terraform apply -var-file=environments/prod.tfvars
```

**Option 3: S3 Remote State** (recommended for teams)

See `backend.tf` for S3 backend configuration.

### Resource Naming

With environment in `project_name`, all resources are clearly separated:

| Resource | Dev | Prod |
|----------|-----|------|
| VPC | `nextjs-app-dev-vpc` | `nextjs-app-prod-vpc` |
| ECS Cluster | `nextjs-app-dev-cluster` | `nextjs-app-prod-cluster` |
| ALB | `nextjs-app-dev-alb` | `nextjs-app-prod-alb` |
| ECR | `nextjs-app-dev` | `nextjs-app-prod` |

### Pushing Docker Images

Each environment has its own ECR repository:

```bash
# Dev image
docker tag myapp:latest <dev-ecr-url>:latest
docker push <dev-ecr-url>:latest

# Prod image (use version tags!)
docker tag myapp:v1.0.0 <prod-ecr-url>:v1.0.0
docker push <prod-ecr-url>:v1.0.0
```

## Cost Estimate

### Development Environment

| Resource | Monthly Cost (USD) |
|----------|-------------------|
| NAT Gateway | ~$32 |
| ALB | ~$16 |
| ECS Fargate (1 task) | ~$10 |
| CloudFront | $0 (disabled) |
| WAF | $0 (disabled) |
| **Dev Total** | **~$58/month** |

### Production Environment

| Resource | Monthly Cost (USD) |
|----------|-------------------|
| NAT Gateway | ~$32 |
| ALB | ~$16 |
| ECS Fargate (2+ tasks) | ~$40+ |
| CloudFront | ~$5-50 (variable) |
| WAF | ~$5+ |
| Route 53 | ~$0.50 |
| **Prod Total** | **~$95+/month** |

*Actual costs depend on traffic and scaling behavior.*

## Configuration Options

### Container Resources

```hcl
# Light app
container_cpu    = 256    # 0.25 vCPU
container_memory = 512    # 512 MB

# Standard app
container_cpu    = 512    # 0.5 vCPU
container_memory = 1024   # 1 GB

# Heavy app (SSR, image processing)
container_cpu    = 1024   # 1 vCPU
container_memory = 2048   # 2 GB
```

### Auto Scaling

```hcl
min_capacity        = 2     # Always run at least 2 for HA
max_capacity        = 10    # Cap at 10 during spikes
cpu_target_value    = 70    # Scale at 70% CPU
memory_target_value = 80    # Scale at 80% memory
```

### CloudFront Price Classes

```hcl
# Cheapest - US, Canada, Europe only
cloudfront_price_class = "PriceClass_100"

# Balanced - Adds Asia, Middle East, Africa
cloudfront_price_class = "PriceClass_200"

# Global - All edge locations
cloudfront_price_class = "PriceClass_All"
```

### WAF Rate Limiting

```hcl
waf_rate_limit = 2000   # Max requests per 5 min per IP
```

## Sample Dockerfile for Next.js

```dockerfile
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV HOSTNAME=0.0.0.0
ENV PORT=3000

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 3000
CMD ["node", "server.js"]
```

**Important:** Enable standalone output in `next.config.js`:

```javascript
module.exports = {
  output: 'standalone',
}
```

## Useful Commands

```bash
# View current state
terraform show

# View outputs
terraform output

# Update only specific resource
terraform apply -target=aws_ecs_service.main

# Destroy everything
terraform destroy

# View ECS logs
aws logs tail /ecs/my-nextjs-app --follow

# Check service status
aws ecs describe-services --cluster my-nextjs-app-cluster --services my-nextjs-app-service

# View scaling activities
aws application-autoscaling describe-scaling-activities --service-namespace ecs
```

## Troubleshooting

### Tasks keep restarting

1. Check health check endpoint exists and returns 200
2. Increase `container_start_period` if app takes time to start
3. Check CloudWatch logs for errors

### CloudFront returns 502/503

1. Check ALB target group health
2. Verify security group allows ALB → ECS traffic
3. Check ECS tasks are running

### WAF blocking legitimate requests

1. Check WAF logs in CloudWatch
2. Temporarily set rule to "count" mode instead of "block"
3. Adjust rate limits if needed

### Slow cold starts

1. Increase `min_capacity` to keep more warm tasks
2. Use Fargate Spot for cost-effective pre-warming
3. Enable provisioned concurrency (requires custom setup)

## Security Best Practices

- ✅ ECS tasks in private subnets (no public IP)
- ✅ WAF protects against OWASP Top 10
- ✅ TLS 1.3 enforced
- ✅ Security groups restrict traffic flow
- ✅ IAM roles with least privilege
- ✅ Container insights for monitoring

## Next Steps

After initial deployment:

1. **Add secrets management** - Use AWS Secrets Manager for API keys, database URLs
2. **Set up CI/CD** - GitHub Actions workflow for automatic deployments
3. **Add monitoring** - CloudWatch alarms, SNS notifications
4. **Configure logging** - Ship logs to DataDog/New Relic if needed
5. **Add database** - RDS/Aurora for data persistence
6. **Add caching** - ElastiCache for session storage
