
# Fetch the default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetch the subnets associated with the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Fetch the specific details of each subnet so we can read their AZs
data "aws_subnet" "default" {
  for_each = toset(data.aws_subnets.default.ids)
  id       = each.value
}

# Filter out the unsupported 'us-east-1e' subnet
locals {
  supported_subnets = [
    for s in data.aws_subnet.default : s.id
    if s.availability_zone != "us-east-1e"
  ]
}

# Provision the EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.37"

  cluster_name    = "cluster-default-vpc"
  cluster_version = "1.34" 
  cluster_upgrade_policy = {
    support_type = "STANDARD"
  }

  # Allow public access to the Kubernetes API server 
  cluster_endpoint_public_access  = true

  # Attach the cluster to the default VPC and its subnets
  vpc_id     = data.aws_vpc.default.id
  subnet_ids = local.supported_subnets

  # Automatically grant cluster admin permissions to the IAM user/role running this Terraform
  enable_cluster_creator_admin_permissions = true

  # Configure Managed Node Groups
  eks_managed_node_groups = {
    spot_node_group = {
      min_size     = 1
      max_size     = 1
      desired_size = 1

      capacity_type  = "SPOT"      
      instance_types = ["t3.medium", "t3a.medium"] 
    }
  }

  tags = {
    Environment = "sandbox"
    Terraform   = "true"
  }
}