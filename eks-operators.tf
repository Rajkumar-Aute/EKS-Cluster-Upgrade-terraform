
# 1. ArgoCD (GitOps Operator)

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = var.argocd_version
  depends_on       = [module.eks]

  values = [
    yamlencode({
      server = {
        # Run ArgoCD server on the core node group
        nodeSelector = {
          role = "core"
        }
      }
      controller = {
        nodeSelector = {
          role = "core"
        }
      }
      repoServer = {
        nodeSelector = {
          role = "core"
        }
      }
      applicationSet = {
        nodeSelector = {
          role = "core"
        }
      }
    })
  ]
}


# Kube-Prometheus-Stack (Prometheus + Grafana + Alertmanager)
resource "helm_release" "kube_prometheus_stack" {
  name             = "monitoring"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  version          = var.prometheus_version

  depends_on = [module.eks]

  values = [
    yamlencode({
      # Grafana Configuration
      grafana = {
        adminPassword = "admin" # Change this in production!
        nodeSelector = {
          role = "core"
        }
      }
      # Prometheus Configuration
      prometheus = {
        prometheusSpec = {
          nodeSelector = {
            role = "core"
          }
          # Prevent Prometheus from consuming too many resources in a lab
          retention      = "5d"
          scrapeInterval = "30s"
        }
      }
      # Alertmanager Configuration
      alertmanager = {
        alertmanagerSpec = {
          nodeSelector = {
            role = "core"
          }
        }
      }
      # Prometheus Operator Configuration
      prometheusOperator = {
        nodeSelector = {
          role = "core"
        }
      }
    })
  ]
}


# 3. External Secrets Operator (ESO)

module "external_secrets_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30"

  role_name                      = "${var.cluster_name}-external-secrets"
  attach_external_secrets_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets"]
    }
  }
}

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  version          = var.external_secrets_version
  depends_on       = [module.eks]

  values = [
    yamlencode({
      installCRDs = true
      serviceAccount = {
        create = true
        name   = "external-secrets"
        annotations = {
          "eks.amazonaws.com/role-arn" = module.external_secrets_irsa_role.iam_role_arn
        }
      }
      nodeSelector = { role = "core" }
    })
  ]
}


# 4. Cert-Manager (Automated TLS/SSL Certificates)

module "cert_manager_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30"

  role_name                     = "${var.cluster_name}-cert-manager"
  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = ["arn:aws:route53:::hostedzone/*"] # Scoped to all zones for lab use

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["cert-manager:cert-manager"]
    }
  }
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = var.cert_manager_version
  depends_on       = [module.eks]

  values = [
    yamlencode({
      installCRDs = true
      serviceAccount = {
        create = true
        name   = "cert-manager"
        annotations = {
          "eks.amazonaws.com/role-arn" = module.cert_manager_irsa_role.iam_role_arn
        }
      }
      nodeSelector = { role = "core" }
    })
  ]
}


# 5. Kyverno (Kubernetes Native Policy Management)

# Kyverno doesn't need AWS IAM permissions; it only needs Kubernetes RBAC.
resource "helm_release" "kyverno" {
  name             = "kyverno"
  repository       = "https://kyverno.github.io/kyverno/"
  chart            = "kyverno"
  namespace        = "kyverno"
  create_namespace = true
  version          = var.kyverno_version
  depends_on       = [module.eks]

  values = [
    yamlencode({
      admissionController = {
        nodeSelector = { role = "core" }
      }
      backgroundController = {
        nodeSelector = { role = "core" }
      }
      cleanupController = {
        nodeSelector = { role = "core" }
      }
      reportsController = {
        nodeSelector = { role = "core" }
      }
    })
  ]
}


# 6. Velero (Disaster Recovery & Cluster Backups)

# Create an S3 Bucket to hold the cluster backups
resource "aws_s3_bucket" "velero_backups" {
  bucket        = "${var.cluster_name}-velero-backups-bucket"
  force_destroy = true # Warning: Set to false in real production!
}

# IAM Role for Velero to access the S3 Bucket and manage EBS Snapshots
module "velero_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30"

  role_name             = "${var.cluster_name}-velero"
  attach_velero_policy  = true
  velero_s3_bucket_arns = [aws_s3_bucket.velero_backups.arn]

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["velero:velero-server"]
    }
  }
}

resource "helm_release" "velero" {
  name             = "velero"
  repository       = "https://vmware-tanzu.github.io/helm-charts"
  chart            = "velero"
  namespace        = "velero"
  create_namespace = true
  version          = var.velero_version
  depends_on       = [module.eks]

  values = [
    yamlencode({
      initContainers = [
        {
          name  = "velero-plugin-for-aws"
          image = "velero/velero-plugin-for-aws:v1.9.0"
          volumeMounts = [{
            mountPath = "/target"
            name      = "plugins"
          }]
        }
      ]
      serviceAccount = {
        server = {
          create = true
          name   = "velero-server"
          annotations = {
            "eks.amazonaws.com/role-arn" = module.velero_irsa_role.iam_role_arn
          }
        }
      }
      configuration = {
        provider = "aws"
        backupStorageLocation = [
          {
            name     = "default"
            provider = "aws"
            bucket   = aws_s3_bucket.velero_backups.id
            config   = { region = var.aws_region }
          }
        ]
        volumeSnapshotLocation = [
          {
            name     = "default"
            provider = "aws"
            config   = { region = var.aws_region }
          }
        ]
      }
      nodeSelector = { role = "core" }
    })
  ]
}