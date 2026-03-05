
# 1. Istio Base (CRDs and Cluster Roles)

resource "helm_release" "istio_base" {
  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  namespace        = "istio-system"
  create_namespace = true
  version          = var.istio_version
  depends_on       = [module.eks]
}


# 2. Istiod (The Control Plane)

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = "istio-system"
  version    = var.istio_version

  # Must wait for the base CRDs to be installed first
  depends_on = [helm_release.istio_base]

  values = [
    yamlencode({
      # Run the control plane on the stable core nodes
      nodeSelector = {
        role = "core"
      }
      meshConfig = {
        # Force strict mTLS across the entire cluster by default
        accessLogFile = "/dev/stdout"
      }
    })
  ]
}


# 3. Istio Ingress Gateway (Handles external traffic entering the mesh)

resource "helm_release" "istio_ingress" {
  name             = "istio-ingressgateway"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "gateway"
  namespace        = "istio-ingress"
  create_namespace = true
  version          = var.istio_version

  # Must wait for the control plane to be ready
  depends_on = [helm_release.istiod]

  values = [
    yamlencode({
      nodeSelector = {
        role = "core"
      }
      service = {
        # We set this to ClusterIP because we want our AWS Load Balancer Controller
        # to handle the external ALB, which will route traffic to this Istio gateway.
        type = "ClusterIP"
      }
    })
  ]
}