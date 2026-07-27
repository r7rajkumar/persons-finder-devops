# Remote state backend: S3 for state storage + DynamoDB for state locking.
#
# Create these resources ONCE before running `terraform init`:
#
#   aws s3api create-bucket \
#     --bucket persons-finder-terraform-state-YOUR_ACCOUNT_ID \
#     --region ap-southeast-2 \
#     --create-bucket-configuration LocationConstraint=ap-southeast-2
#
#   aws s3api put-bucket-versioning \
#     --bucket persons-finder-terraform-state-YOUR_ACCOUNT_ID \
#     --versioning-configuration Status=Enabled
#
#   aws s3api put-bucket-encryption \
#     --bucket persons-finder-terraform-state-YOUR_ACCOUNT_ID \
#     --server-side-encryption-configuration '{
#       "Rules": [{
#         "ApplyServerSideEncryptionByDefault": {
#           "SSEAlgorithm": "AES256"
#         },
#         "BucketKeyEnabled": false
#       }]
#     }'
#
#   aws dynamodb create-table \
#     --table-name persons-finder-terraform-lock \
#     --attribute-definitions AttributeName=LockID,AttributeType=S \
#     --key-schema AttributeName=LockID,KeyType=HASH \
#     --billing-mode PAY_PER_REQUEST \
#     --region ap-southeast-2
#
# Then uncomment the backend block below and run `terraform init`.

# terraform {
#   backend "s3" {
#     bucket         = "persons-finder-terraform-state-YOUR_ACCOUNT_ID"
#     key            = "persons-finder/terraform.tfstate"
#     region         = "ap-southeast-2"
#     encrypt        = true
#     dynamodb_table = "persons-finder-terraform-lock"
#   }
# }
