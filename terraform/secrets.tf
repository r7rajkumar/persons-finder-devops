resource "aws_secretsmanager_secret" "openai_api_key" {
  name                    = "${var.app_name}/openai-api-key"
  description             = "OPENAI_API_KEY for persons-finder — value set out-of-band, never in TF state"
  recovery_window_in_days = 7

  tags = {
    Application = var.app_name
    ManagedBy   = "terraform"
  }
}

# Deliberately no aws_secretsmanager_secret_version resource here — that
# would put the key's value in the Terraform state file in plaintext.
# Set it once, out-of-band, after `terraform apply`:
#
#   aws secretsmanager put-secret-value \
#     --secret-id persons-finder/openai-api-key \
#     --secret-string "$OPENAI_API_KEY"
