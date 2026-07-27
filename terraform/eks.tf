# This repo intentionally does NOT provision an EKS cluster — spinning one
# up (and billing for it) isn't useful for reviewing a take-home, and most
# real environments already have a cluster the app would join instead.
#
# For a from-scratch cluster, the module call would look like:
#
# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 20.0"
#
#   cluster_name    = "${var.app_name}-cluster"
#   cluster_version = "1.29"
#
#   vpc_id     = module.vpc.vpc_id
#   subnet_ids = module.vpc.private_subnets
#
#   eks_managed_node_groups = {
#     default = {
#       instance_types = ["t3.medium"]
#       min_size       = 2
#       max_size       = 6
#       desired_size   = 2
#     }
#   }
#
#   enable_irsa = true
# }
#
# `module.eks.oidc_provider_arn` from that module's outputs is what feeds
# `eks_oidc_provider_arn` in irsa.tf above.
