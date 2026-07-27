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

variable "k8s_namespace" {
  description = "Kubernetes namespace for the app"
  type        = string
  default     = "persons-finder"
}

variable "k8s_service_account" {
  description = "Kubernetes service account name for IRSA"
  type        = string
  default     = "persons-finder"
}
