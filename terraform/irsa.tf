# IAM Roles for Service Accounts (IRSA): lets the persons-finder pod assume
# an IAM role scoped to exactly one Secrets Manager secret, via its K8s
# service account — instead of the whole node's IAM role being able to read
# every secret in the account.
#
# Requires eks_oidc_provider_arn to be set (see variables.tf) once you point
# this at a real cluster; left as a variable rather than a resource here
# because this repo doesn't provision the cluster (see eks.tf).

data "aws_iam_policy_document" "irsa_trust" {
  count = var.eks_oidc_provider_arn != "" ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.eks_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.eks_oidc_provider_arn, "/^.*oidc-provider\\//", "")}:sub"
      values   = ["system:serviceaccount:${var.k8s_namespace}:${var.k8s_service_account}"]
    }
  }
}

resource "aws_iam_role" "persons_finder_pod" {
  count              = var.eks_oidc_provider_arn != "" ? 1 : 0
  name               = "${var.app_name}-pod-role"
  assume_role_policy = data.aws_iam_policy_document.irsa_trust[0].json
}

data "aws_iam_policy_document" "read_openai_secret" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.openai_api_key.arn]
  }
}

resource "aws_iam_role_policy" "persons_finder_pod_secrets" {
  count  = var.eks_oidc_provider_arn != "" ? 1 : 0
  name   = "${var.app_name}-read-openai-secret"
  role   = aws_iam_role.persons_finder_pod[0].id
  policy = data.aws_iam_policy_document.read_openai_secret.json
}
