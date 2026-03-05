environment  = "learning"
aws_region   = "us-east-1"
cluster_name = "eks-cluster"
vpc_cidr     = "10.0.0.0/16"

# =========================================================================
# EKS UPGRADE PRACTICE & ADD-ON VERSIONS
# To practice upgrading, comment out the "Old Versions" block 
# and uncomment the "New Versions" block, then run `terraform apply`.
# =========================================================================

# -------------------------------------------------------------------------
# --- [ OLD VERSIONS ] (Start with these) ---
# -------------------------------------------------------------------------

# KUBERNETES & CORE CONTROLLERS
cluster_version            = "1.29"
alb_controller_version     = "1.7.1"
cluster_autoscaler_version = "9.34.0"
metrics_server_version     = "3.12.0"

# GITOPS & MONITORING
argocd_version             = "6.7.11"
prometheus_version         = "57.2.0"

# DEVSECOPS & DR TOOLS
fluentbit_version          = "0.23.0"
external_secrets_version   = "0.9.13"
cert_manager_version       = "1.14.4"
kyverno_version            = "3.1.4"
velero_version             = "5.3.0"

# SERVICE MESH
istio_version = "1.21.0"

# -------------------------------------------------------------------------
# --- [ NEW VERSIONS ] (Switch to these for upgrade practice) ---
# -------------------------------------------------------------------------

# KUBERNETES & CORE CONTROLLERS
# cluster_version            = "1.30"
# alb_controller_version     = "1.8.1"
# cluster_autoscaler_version = "9.37.0"
# metrics_server_version     = "3.12.1"

# GITOPS & MONITORING
# argocd_version             = "7.3.0"
# prometheus_version         = "58.0.0"

# DEVSECOPS & DR TOOLS
# fluentbit_version          = "0.28.0"
# external_secrets_version   = "0.9.18"
# cert_manager_version       = "1.15.0"
# kyverno_version            = "3.2.0"
# velero_version             = "6.0.0"

# SERVICE MESH
# istio_version = "1.22.0"