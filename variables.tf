variable "AWS_REGION" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "min-node-groups-nodes" {
  description = "The minimum number of nodes for the EKS cluster"
  type        = number
}

variable "max-node-groups-nodes" {
  description = "The maximum number of nodes for the EKS cluster"
  type        = number
}

variable "desired-node-groups-nodes" {
  description = "The desired number of nodes for the EKS cluster"
  type        = number
}