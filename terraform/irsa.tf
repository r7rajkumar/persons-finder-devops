# IAM Roles for Service Accounts (IRSA): lets the persons-finder pod assume
# an IAM role scoped to exactly one Secrets Manager secret, via its K8s
# service account — instead of the whole node's IAM role being able to read
# every secret in the account.

locals {
  # EKS module always present now — use its OIDC output directly
  oidc_provider_arn = module.eks.oidc_provider_arn
  create_irsa       = local.oidc_provider_arn != ""
}

data "aws_iam_policy_document" "irsa_trust" {
  count = local.create_irsa ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(local.oidc_provider_arn, "/^.*oidc-provider\\//", "")}:sub"
      values   = ["system:serviceaccount:${var.k8s_namespace}:${var.k8s_service_account}"]
    }
  }
}

resource "aws_iam_role" "persons_finder_pod" {
  count              = local.create_irsa ? 1 : 0
  name               = "${var.app_name}-pod-role"
  assume_role_policy = data.aws_iam_policy_document.irsa_trust[0].json

  tags = {
    Application = var.app_name
    ManagedBy   = "terraform"
  }
}

data "aws_iam_policy_document" "read_openai_secret" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.openai_api_key.arn]
  }
}

resource "aws_iam_role_policy" "persons_finder_pod_secrets" {
  count  = local.create_irsa ? 1 : 0
  name   = "${var.app_name}-read-openai-secret"
  role   = aws_iam_role.persons_finder_pod[0].id
  policy = data.aws_iam_policy_document.read_openai_secret.json
}

output "pod_iam_role_arn" {
  value       = local.create_irsa ? aws_iam_role.persons_finder_pod[0].arn : ""
  description = "ARN of the IAM role for the pod service account (annotate K8s SA with this)"
}
