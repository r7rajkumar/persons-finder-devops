# EKS cluster for running the persons-finder deployment.
# Provisions a real EKS cluster (~$133/month for control plane + 2x t3.medium nodes).
# Run `terraform destroy` when done testing to avoid ongoing costs.

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.app_name}-cluster"
  cluster_version = "1.32"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Allow access to the cluster from your current IP
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 6
      desired_size   = 2

      # Taints/labels optional — for this simple app, defaults are fine
    }
  }

  # Enable IRSA (IAM Roles for Service Accounts)
  enable_irsa = true

  tags = {
    Application = var.app_name
    ManagedBy   = "terraform"
  }
}

# Output the OIDC provider ARN — needed for irsa.tf
output "eks_oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "ARN of the EKS OIDC provider — use this for eks_oidc_provider_arn variable in irsa.tf"
}

output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "Name of the EKS cluster"
}

output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "Endpoint for EKS cluster API server"
}

# To configure kubectl after `terraform apply`:
#   aws eks update-kubeconfig --region ap-southeast-2 --name persons-finder-cluster
