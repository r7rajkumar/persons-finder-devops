# VPC for the EKS cluster.
# Creates a dedicated VPC with public + private subnets across 2 AZs.
# EKS nodes run in private subnets; the load balancer lives in public subnets.

# Dynamically fetch available AZs in the region — avoids hardcoding "a","b"
# which can fail if a region doesn't have those specific AZs.
data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.app_name}-vpc"
  cidr = "10.0.0.0/16"

  # Use first 2 available AZs dynamically — works across all AWS regions
  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true # one NAT GW is cheaper for dev; use false for prod HA
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags required by EKS for subnet auto-discovery
  public_subnet_tags = {
    "kubernetes.io/role/elb"                        = "1"
    "kubernetes.io/cluster/${var.app_name}-cluster" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"               = "1"
    "kubernetes.io/cluster/${var.app_name}-cluster" = "shared"
  }

  tags = {
    Application = var.app_name
    ManagedBy   = "terraform"
  }
}
