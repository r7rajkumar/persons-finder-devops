#!/usr/bin/env bash
# setup-backend.sh: Create S3 bucket + DynamoDB table for Terraform remote state
#
# Run this ONCE before `terraform init`:
#   chmod +x setup-backend.sh
#   ./setup-backend.sh YOUR_AWS_ACCOUNT_ID ap-southeast-2

set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: $0 <aws-account-id> <region>"
  echo "Example: $0 123456789012 ap-southeast-2"
  exit 1
fi

ACCOUNT_ID=$1
REGION=$2
BUCKET_NAME="persons-finder-terraform-state-${ACCOUNT_ID}"
TABLE_NAME="persons-finder-terraform-lock"

echo "=== Creating S3 bucket for state storage ==="
aws s3api create-bucket \
  --bucket "${BUCKET_NAME}" \
  --region "${REGION}" \
  --create-bucket-configuration LocationConstraint="${REGION}" || {
    echo "Bucket might already exist, continuing..."
  }

echo "=== Enabling versioning on S3 bucket ==="
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled

echo "=== Enabling encryption on S3 bucket ==="
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      },
      "BucketKeyEnabled": false
    }]
  }'

echo "=== Blocking public access on S3 bucket ==="
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "=== Creating DynamoDB table for state locking ==="
aws dynamodb create-table \
  --table-name "${TABLE_NAME}" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "${REGION}" || {
    echo "Table might already exist, continuing..."
  }

echo ""
echo "✅ Backend infrastructure created:"
echo "   S3 Bucket: ${BUCKET_NAME}"
echo "   DynamoDB Table: ${TABLE_NAME}"
echo ""
echo "Next steps:"
echo "1. Edit terraform/backend.tf and uncomment the backend block"
echo "2. Replace YOUR_ACCOUNT_ID with ${ACCOUNT_ID}"
echo "3. Run: terraform init"
