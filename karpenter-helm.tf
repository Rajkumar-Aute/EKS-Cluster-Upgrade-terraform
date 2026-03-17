# Retrieve the authentication token to pull the Karpenter image from AWS Public ECR
data "aws_ecrpublic_authorization_token" "token" {}


# Install the Karpenter Helm Chart
resource "helm_release" "karpenter" {
  namespace           = "karpenter"
  create_namespace    = true
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "1.0.1" # Using the stable v1.0+ release

  values = [
    <<-EOT
    serviceAccount:
      annotations:
        # Attaches the IRSA IAM role we created earlier to the pod
        eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}
    settings:
      # Tells Karpenter which cluster it is managing
      clusterName: ${module.eks.cluster_name}
      # Tells Karpenter which SQS queue to listen to for Spot interruptions
      interruptionQueue: ${module.karpenter.queue_name}
    EOT
  ]
}