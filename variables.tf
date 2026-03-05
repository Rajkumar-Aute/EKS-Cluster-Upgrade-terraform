# variables.tf

# Environment variable to distinguish between Dev, Staging, and Prod.
variable "environment" {
  description = "Deployment environment in this code used 'learning' as environment"
  type        = string
  default     = "learning"
}


# AWS Region
#    The region where your cluster and resources will be deployed.
#    Default is "us-east-1" (N. Virginia). Change this if you are in Europe/Asia.
variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

# Cluster Name
#    This name will appear in the AWS Console and your kubeconfig file.
variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
  default     = "eks-cluster"
}

# VPC Network Range
#    The CIDR block for the Virtual Private Cloud.
#    "10.0.0.0/16" provides 65,536 IP addresses, plenty for a large cluster.
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}


# Resource Versions (Controlled via learning.tfvars)

variable "cluster_version" {
  description = "Kubernetes Version, default is latest stable version from the external data source"
  type        = string
  default = "latest"
}

variable "alb_controller_version" {
  description = "Helm chart version for AWS Load Balancer Controller"
  type        = string
  default = "latest"
}

variable "cluster_autoscaler_version" {
  description = "Helm chart version for Cluster Autoscaler"
  type        = string
  default = "latest"
}

variable "metrics_server_version" {
  description = "Helm chart version for Metrics Server"
  type        = string
  default = "latest"
}

variable "argocd_version" {
  description = "Helm chart version for ArgoCD"
  type        = string
  default     = "latest"
}

variable "prometheus_version" {
  description = "Helm chart version for Kube-Prometheus-Stack (Prometheus & Grafana)"
  type        = string
  default     = "latest"
}

variable "fluentbit_version" {
  description = "Helm chart version for AWS Fluent Bit (Logging)"
  type        = string
}

variable "external_secrets_version" {
  description = "Helm chart version for External Secrets Operator"
  type        = string
}

variable "cert_manager_version" {
  description = "Helm chart version for Cert-Manager"
  type        = string
}

variable "kyverno_version" {
  description = "Helm chart version for Kyverno Policy Engine"
  type        = string
}

variable "velero_version" {
  description = "Helm chart version for Velero (Disaster Recovery)"
  type        = string
}

variable "istio_version" {
  description = "Helm chart version for Istio Service Mesh"
  type        = string
}