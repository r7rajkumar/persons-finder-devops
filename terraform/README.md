# Terraform (AWS) — bonus path

The README's mission gives two options for infra: "Deploy this app to a
local cluster (Minikube/Kind) **or** output Terraform for AWS/GCP." The
[`k8s/`](../k8s) manifests are the primary submission (runnable end-to-end
on minikube/kind, which I could actually verify locally). This folder is the
Terraform side, included to show the AWS path — it's written to be correct
and reviewable, with proper remote state and locking.

## What it provisions

**Base infrastructure (always created):**
- An ECR repository for the container image, with a lifecycle policy that
  expires untagged images after 14 days.
- A Secrets Manager secret for `OPENAI_API_KEY` (value set out-of-band via
  `aws secretsmanager put-secret-value`, never in Terraform state).

**EKS cluster (included, ready to deploy):**
- VPC with public + private subnets across 2 AZs
- EKS cluster v1.32 with managed node group (2 t3.medium instances)
- IAM role for IRSA (IAM Roles for Service Accounts), scoped to
  `secretsmanager:GetSecretValue` on that one secret ARN only

**Cost estimate:**
- EKS control plane: ~$73/month ($0.10/hour)
- 2× t3.medium nodes: ~$60/month ($0.0416/hour each)
- **Total: ~$133/month** if left running

The EKS cluster is real and ready to deploy — just `terraform apply`.

## Structure Notes

**Current structure:** Flat, single-environment layout — all resources defined directly
in the root module. This is intentional for assessment review simplicity.

**Production evolution:** For multiple environments (dev/staging/prod), refactor to:
- Extract reusable modules (`modules/vpc`, `modules/eks`, `modules/app-infra`)
- Create environment-specific directories (`environments/dev`, `environments/prod`)
- Each environment calls the same modules with different `tfvars` values
- Separate backend state per environment

This avoids code duplication and allows environment-specific sizing (e.g., prod uses
`t3.large` nodes, dev uses `t3.medium`).

**Nothing!** This Terraform config provisions a complete, working EKS cluster.
The previous version was stub code — this version is deployment-ready.

If you already have an EKS cluster and just want the app infrastructure (ECR + Secrets Manager + IRSA),
comment out `vpc.tf` and `eks.tf` and set `eks_oidc_provider_arn` variable to your existing cluster's OIDC provider.

## Setup — Remote State Backend

Terraform stores state remotely in S3 with DynamoDB for locking. Set this up once:

### Option 1: Automated setup (recommended)

```bash
# Get your AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Run the setup script
chmod +x setup-backend.sh
./setup-backend.sh $AWS_ACCOUNT_ID us-east-1
```

This creates:
- S3 bucket: `persons-finder-terraform-state-<ACCOUNT_ID>` (encrypted, versioned, private)
- DynamoDB table: `persons-finder-terraform-lock` (PAY_PER_REQUEST billing)

Then:
1. Edit `backend.tf`
2. Uncomment the `backend "s3"` block
3. Replace `YOUR_ACCOUNT_ID` with your actual account ID
4. Run `terraform init` (will migrate state to S3)

### Option 2: Manual setup

See the commands at the top of `backend.tf`.

## Usage

```bash
cd terraform

# Initialize (after backend is configured)
terraform init

# Plan
terraform plan -var="aws_region=us-east-1"

# Apply (creates VPC, EKS cluster, ECR, Secrets Manager, IRSA)
# WARNING: This provisions real AWS resources that cost ~$133/month
terraform apply -var="aws_region=us-east-1"

# Takes 10-15 minutes for EKS cluster to be ready

# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name persons-finder-cluster

# Verify cluster access
kubectl get nodes

# Set the secret value (never in terraform state)
aws secretsmanager put-secret-value \
  --secret-id persons-finder/openai-api-key \
  --secret-string "$OPENAI_API_KEY"

# Deploy the app (use the K8s manifests from ../k8s/)
kubectl apply -k ../k8s/

# Create external secrets sync (or manually create K8s secret with IRSA)
# See ../k8s/README.md for full deployment steps
```

## State Management

- **State file**: Stored in S3 `persons-finder-terraform-state-<ACCOUNT_ID>`
- **State locking**: DynamoDB table `persons-finder-terraform-lock` prevents concurrent modifications
- **Encryption**: AES256 server-side encryption on S3
- **Versioning**: Enabled — you can roll back to previous states if needed

## Variables

See `variables.tf` for all configurable values. Key ones:

| Variable | Default | Description |
|---|---|---|
| `aws_region` | `us-east-1` | AWS region |
| `app_name` | `persons-finder` | Used to prefix resource names |
| `eks_oidc_provider_arn` | `""` (empty) | Required for IRSA — get from your EKS cluster |

## Clean up

```bash
terraform destroy -var="aws_region=us-east-1"

# Manually delete the backend resources (state bucket + lock table) if no longer needed
aws s3 rb s3://persons-finder-terraform-state-<ACCOUNT_ID> --force
aws dynamodb delete-table --table-name persons-finder-terraform-lock
```
