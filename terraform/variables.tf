variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-southeast-2"
}

variable "app_name" {
  description = "Name used to tag/prefix resources"
  type        = string
  default     = "persons-finder"
}

variable "eks_oidc_provider_arn" {
  description = <<-EOT
    ARN of the EKS cluster's OIDC provider (from `terraform output` on your
    cluster module, or `aws eks describe-cluster`). Required to wire up
    IRSA in irsa.tf. Left unset here since this repo doesn't provision the
    cluster itself — see eks.tf.
  EOT
  type    = string
  default = ""
}

variable "k8s_namespace" {
  type    = string
  default = "persons-finder"
}

variable "k8s_service_account" {
  type    = string
  default = "persons-finder"
}
