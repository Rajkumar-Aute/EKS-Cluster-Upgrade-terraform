terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.AWS_REGION
  default_tags {
    # These tags will be applied to all AWS resources created by this Terraform configuration, unless overridden at the resource level.
    tags = {
      Project     = "EKS-Upgrade-lab-Setup"
      Environment = "sandbox"
      ManagedBy   = "Terraform"
      CostCenter  = "Learning"
    }
  }
}