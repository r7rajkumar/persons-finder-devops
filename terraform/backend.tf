# Remote state backend: S3 for state storage + DynamoDB for state locking.
#
# STEP 1 — Bootstrap the backend infrastructure (one-time only):
#
#   cd terraform
#   chmod +x setup-backend.sh
#   ./setup-backend.sh $(aws sts get-caller-identity --query Account --output text) ap-southeast-2
#
# STEP 2 — Uncomment the backend block below and run `terraform init`
#
# NOTE: The backend block does not support variables or expressions — the
# bucket name must be a literal string. Get your account ID with:
#   aws sts get-caller-identity --query Account --output text
# Then replace YOUR_ACCOUNT_ID below with the actual value before running init.

# terraform {
#   backend "s3" {
#     bucket         = "persons-finder-terraform-state-YOUR_ACCOUNT_ID"
#     key            = "persons-finder/terraform.tfstate"
#     region         = "ap-southeast-2"
#     encrypt        = true
#     dynamodb_table = "persons-finder-terraform-lock"
#   }
# }
#
# Alternative: pass backend config at init time (avoids editing this file):
#
#   ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
#   terraform init \
#     -backend-config="bucket=persons-finder-terraform-state-${ACCOUNT_ID}" \
#     -backend-config="key=persons-finder/terraform.tfstate" \
#     -backend-config="region=ap-southeast-2" \
#     -backend-config="encrypt=true" \
#     -backend-config="dynamodb_table=persons-finder-terraform-lock"
#
# The -backend-config approach is cleaner — no account ID hardcoded in any file.
