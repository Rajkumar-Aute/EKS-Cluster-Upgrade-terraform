# Enterprise-Grade DevSecOps EKS Cluster

Welcome to the **DevSecOpsGuru.in** advanced Amazon EKS cluster lab! 

This repository contains the Terraform Infrastructure as Code (IaC) required to provision a fully production-ready, zero-trust, and observable Kubernetes cluster. It goes beyond standard cluster creation by automatically bootstrapping the essential GitOps, security, service mesh, and disaster recovery operators used by elite DevSecOps engineering teams.

---

## Architecture & Included Components

This Terraform project provisions a highly available AWS VPC (`10.0.0.0/16`), an EKS Control Plane, and distinct Node Groups (Core On-Demand and Application Spot nodes). It also installs the following cluster add-ons using IAM Roles for Service Accounts (IRSA) for strict least-privilege security:

### 1. Core Infrastructure (Controllers)
* **AWS Load Balancer Controller:** Dynamically provisions AWS ALBs/NLBs for your Ingress resources.
* **Cluster Autoscaler:** Automatically scales node groups based on workload CPU/Memory demands.
* **Metrics Server:** Provides resource utilization metrics to enable Horizontal Pod Autoscaling (HPA).
* **AWS EBS CSI Driver:** Provisions persistent block storage for stateful workloads.

### 2. GitOps & Observability
* **ArgoCD:** Declarative, GitOps continuous delivery tool for automated deployments.
* **Kube-Prometheus-Stack:** Installs the Prometheus Operator and Grafana for comprehensive cluster monitoring.
* **AWS for Fluent Bit:** Centralized log shipper that forwards all container logs to AWS CloudWatch.

### 3. Security, Policy & Secrets (DevSecOps)
* **External Secrets Operator (ESO):** Securely fetches credentials from AWS Secrets Manager directly into Kubernetes.
* **Cert-Manager:** Automates the lifecycle and renewal of TLS/SSL certificates (e.g., Let's Encrypt).
* **Kyverno:** Kubernetes-native policy engine to enforce security standards (e.g., blocking root containers).

### 4. Service Mesh
* **Istio:** Provides zero-trust mTLS encryption between microservices, advanced traffic routing, and deep network observability.

### 5. Disaster Recovery
* **Velero:** Backs up cluster state and persistent volumes to an automatically provisioned Amazon S3 bucket.

---

## Phase 1: Deployment

### Prerequisites
* AWS CLI installed and authenticated (e.g., `aws sso login` or configured IAM credentials).
* Terraform (`>= 1.3.0`) installed.
* `kubectl` and `helm` installed.

### Provision the Infrastructure
Run the following commands to deploy the cluster using the learning environment variables.

```bash
# Initialize Terraform and download providers/modules
terraform init

# Review the execution plan
terraform plan -var-file=environment/learning.tfvars 

# Deploy the infrastructure (Takes ~15-20 minutes)
terraform apply -var-file=environment/learning.tfvars
```


Once the deployment completes, connect your local terminal to the new cluster:

```Bash
aws eks --region us-east-1 update-kubeconfig --name eks-cluster-learning
```

## Phase 2: Configuration & Access
The infrastructure is running, but the DevSecOps operators must be configured to handle workloads.

1. Accessing Dashboards (ArgoCD & Grafana)
ArgoCD UI:

* Retrieve the auto-generated admin password:

```Bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```
* Port-forward to your local machine:

```Bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
* Open https://localhost:8080 (Username: admin).

**Grafana UI:**

* Port-forward the service:

``Bash
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
```

* Open http://localhost:3000 (Username: admin, Password: admin).


2. Enabling Istio Service Mesh
To secure your applications with strict mTLS, you simply instruct Istio to inject Envoy proxy sidecars into your application namespaces.

```Bash
# Enable automatic sidecar injection for the default namespace
kubectl label namespace default istio-injection=enabled
```

3. Configuring External Secrets Operator (ESO)
Tell ESO how to authenticate with AWS Secrets Manager by creating a ClusterSecretStore.

```YAML
# Apply with: kubectl apply -f eso-store.yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: aws-secrets-manager
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets
            namespace: external-secrets
```

4. Configuring Cert-Manager
Set up a Let's Encrypt ClusterIssuer to automatically provide valid SSL certificates for your Ingresses.

```YAML
# Apply with: kubectl apply -f letsencrypt-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: [https://acme-v02.api.letsencrypt.org/directory](https://acme-v02.api.letsencrypt.org/directory)
    email: admin@devsecopsguru.in
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: alb
```

5. Enforcing DevSecOps Policies (Kyverno)
Test the Kyverno policy engine by applying a rule that prevents any pod from running as the root user.

```YAML
# Apply with: kubectl apply -f disallow-root.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-root-user
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-runasnonroot
      match:
        any:
        - resources:
            kinds:
              - Pod
      validate:
        message: "Running as root is not allowed. Set runAsNonRoot to true."
        pattern:
          spec:
            securityContext:
              runAsNonRoot: true
```

6. Testing Disaster Recovery (Velero)
Velero is pre-configured to communicate with your Terraform-managed S3 bucket.

```Bash
# Take a manual backup of the entire cluster
velero backup create day2-initial-backup

# Check the backup status
velero backup describe day2-initial-backup

# Restore the cluster (e.g., if a namespace is accidentally deleted)
velero restore create --from-backup day2-initial-backup
```


## Phase 3: The EKS Upgrade Lab
Upgrading Kubernetes in production is notoriously difficult. This lab allows you to practice safe upgrades using Terraform variables.

1. Open environment/learning.tfvars.

2. Comment out the OLD VERSIONS block (e.g., K8s 1.29 and older Helm charts).

3. Uncomment the NEW VERSIONS block (e.g., K8s 1.30 and upgraded Helm charts).

4. Run the upgrade:

```Bash
terraform plan -var-file=environment/learning.tfvars
terraform apply -var-file=environment/learning.tfvars
```
Note: Terraform will systematically upgrade the Control Plane, cycle the worker nodes gracefully, and upgrade the operator CRDs/Helm releases without downtime.

## Cleanup
To avoid incurring AWS charges when you are done practicing, destroy the cluster:

```Bash
terraform destroy -var-file=environment/learning.tfvars
```
(Note: You must manually delete any ALBs/NLBs created by the Load Balancer Controller in the AWS console before Terraform can successfully destroy the VPC).