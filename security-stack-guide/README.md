# Security Stack: Cert-Manager + Vault
# if vault pods failing to start, remove cluster-keys.json file.

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Components](#components)
4. [How They Work Together](#how-they-work-together)
5. [Setup on Kind](#setup-on-kind)
6. [Setup on Minikube](#setup-on-minikube)
7. [Usage Examples](#usage-examples)
8. [Troubleshooting](#troubleshooting)

---

## Overview

Your security namespace runs two critical infrastructure components:

### **Cert-Manager**
- **Purpose**: Automated TLS/SSL certificate management for Kubernetes
- **What it does**: 
  - Automatically provisions and renews certificates
  - Integrates with Let's Encrypt, private CAs, and other issuers
  - Injects certificates into Kubernetes secrets
  - Manages certificate lifecycle (renewal, rotation)

### **HashiCorp Vault**
- **Purpose**: Secrets management and encryption service
- **What it does**:
  - Stores sensitive data (API keys, passwords, tokens)
  - Provides dynamic secrets generation
  - Encrypts data at rest and in transit
  - Manages access control policies
  - Integrates with Kubernetes authentication

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Security Namespace                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────────┐              ┌──────────────────────┐    │
│  │   Cert-Manager       │              │    HashiCorp Vault    │    │
│  │                      │              │                       │    │
│  │  ┌────────────────┐  │              │  ┌─────────────────┐ │    │
│  │  │ Controller     │  │              │  │ Vault Server    │ │    │
│  │  │ (Main Logic)   │  │              │  │ (HA Mode)       │ │    │
│  │  └────────────────┘  │              │  │                 │ │    │
│  │                      │              │  │  - vault-0      │ │    │
│  │  ┌────────────────┐  │   Creates    │  │  - vault-1      │ │    │
│  │  │ CA Injector    │  │─────certs───▶│  │  - vault-2      │ │    │
│  │  │ (Injects CA)   │  │   for TLS    │  │                 │ │    │
│  │  └────────────────┘  │              │  │  (Raft Storage) │ │    │
│  │                      │              │  └─────────────────┘ │    │
│  │  ┌────────────────┐  │              │                       │    │
│  │  │ Webhook        │  │              │  ┌─────────────────┐ │    │
│  │  │ (Validates)    │  │              │  │ Agent Injector  │ │    │
│  │  └────────────────┘  │              │  │ (Sidecar Pod)   │ │    │
│  └──────────────────────┘              │  └─────────────────┘ │    │
│             │                           │          │            │    │
│             │ Manages Certificates      │          │ Injects    │    │
│             ▼                           │          ▼ Secrets    │    │
│  ┌──────────────────────┐              │  ┌─────────────────┐ │    │
│  │  Kubernetes Secrets  │              │  │ Application Pods│ │    │
│  │  (TLS Certificates)  │              │  │ (with secrets)  │ │    │
│  └──────────────────────┘              │  └─────────────────┘ │    │
│                                         │                       │    │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
                    ┌───────────────────────┐
                    │  Application Pods     │
                    │  (data, cn-data, etc) │
                    │                       │
                    │  - Use TLS certs from │
                    │    cert-manager       │
                    │  - Fetch secrets from │
                    │    Vault              │
                    └───────────────────────┘
```

---

## Components

### Cert-Manager Pods

| Pod | Purpose | Ready Status |
|-----|---------|--------------|
| `cert-manager-*` | Main controller - watches for Certificate resources | 1/1 Running |
| `cert-manager-cainjector-*` | Injects CA bundles into webhooks/APIServices | 1/1 Running |
| `cert-manager-webhook-*` | Validates cert-manager CRDs | 1/1 Running |

### Vault Pods

| Pod | Purpose | Ready Status |
|-----|---------|--------------|
| `vault-0` | Primary Vault server (Raft leader) | 0/1 Running (needs unsealing!) |
| `vault-1` | Secondary Vault server (Raft follower) | 1/1 Running |
| `vault-2` | Secondary Vault server (Raft follower) | 1/1 Running |
| `vault-agent-injector-*` | Injects Vault sidecar into annotated pods | 1/1 Running |

**Note**: `vault-0` is 0/1 because it needs to be unsealed (see vault unsealing section).

---

## How They Work Together

### 1. **Cert-Manager → Vault**
Cert-manager can create TLS certificates for Vault's web interface and API:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: vault-tls
  namespace: security
spec:
  secretName: vault-tls
  issuerRef:
    name: ca-issuer
    kind: Issuer
  dnsNames:
    - vault.security.svc.cluster.local
```

### 2. **Vault → Applications**
Applications use Vault annotations to inject secrets:

```yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/role: "my-app"
    vault.hashicorp.com/agent-inject-secret-config: "secret/data/myapp/config"
spec:
  serviceAccountName: my-app
```

### 3. **Cert-Manager → Applications**
Applications reference certificates created by cert-manager:

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      volumes:
        - name: tls
          secret:
            secretName: my-app-tls  # Created by cert-manager
```

---

## Setup on Kind

### Prerequisites
```bash
# Install Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### 1. Create Kind Cluster

Save as `kind-security-cluster.yaml`:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: security-demo

nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 8200
    hostPort: 8200
    protocol: TCP
  - containerPort: 30443
    hostPort: 30443
    protocol: TCP
- role: worker
- role: worker
```

Create cluster:
```bash
kind create cluster --config kind-security-cluster.yaml
```

### 2. Install Cert-Manager

```bash
# Add cert-manager Helm repo
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Create namespace
kubectl create namespace security

# Install cert-manager
helm install cert-manager jetstack/cert-manager \
  --namespace security \
  --version v1.13.2 \
  --set installCRDs=true \
  --wait

# Verify installation
kubectl get pods -n security -l app.kubernetes.io/instance=cert-manager
```

### 3. Install Vault

```bash
# Add HashiCorp Helm repo
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Install Vault
helm install vault hashicorp/vault \
  --namespace security \
  --set server.ha.enabled=true \
  --set server.ha.raft.enabled=true \
  --set server.ha.replicas=3 \
  --wait

# Verify installation
kubectl get pods -n security -l app.kubernetes.io/name=vault
```

### 4. Initialize and Unseal Vault

See the [Vault Setup Script](#vault-setup-script) section below.

---

## Setup on Minikube

### Prerequisites
```bash
# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start Minikube with enough resources
minikube start --cpus=4 --memory=8192 --driver=docker
```

### Installation Steps

Follow the same steps as Kind:
1. Create namespace: `kubectl create namespace security`
2. Install cert-manager (same helm commands as above)
3. Install Vault (same helm commands as above)
4. Initialize and unseal Vault

### Access Services

```bash
# Port-forward Vault
kubectl port-forward -n security svc/vault 8200:8200 &

# Access Vault UI
open http://localhost:8200

# Port-forward cert-manager webhook (for debugging)
kubectl port-forward -n security svc/cert-manager-webhook 10250:10250 &
```

---

## Vault Setup Script

Create `setup-vault.sh`:

```bash
#!/bin/bash
set -e

NS="security"

echo "Waiting for vault-0 to be running..."
kubectl wait --for=condition=ready pod/vault-0 -n $NS --timeout=300s || true

echo "Initializing Vault..."
kubectl exec -n $NS vault-0 -- vault operator init \
  -key-shares=1 \
  -key-threshold=1 \
  -format=json > cluster-keys.json

echo "Extracting keys..."
UNSEAL_KEY=$(cat cluster-keys.json | jq -r ".unseal_keys_b64[0]")
ROOT_TOKEN=$(cat cluster-keys.json | jq -r ".root_token")

echo "Unsealing vault-0..."
kubectl exec -n $NS vault-0 -- vault operator unseal $UNSEAL_KEY

echo "Logging into vault-0..."
kubectl exec -n $NS vault-0 -- vault login $ROOT_TOKEN

echo "Joining and unsealing vault-1..."
kubectl exec -n $NS vault-1 -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec -n $NS vault-1 -- vault operator unseal $UNSEAL_KEY

echo "Joining and unsealing vault-2..."
kubectl exec -n $NS vault-2 -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec -n $NS vault-2 -- vault operator unseal $UNSEAL_KEY

echo "Enabling Kubernetes auth..."
kubectl exec -n $NS vault-0 -- vault auth enable kubernetes

echo "Configuring Kubernetes auth..."
kubectl exec -n $NS vault-0 -- sh -c 'vault write auth/kubernetes/config \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"'

echo "Enabling KV secrets engine..."
kubectl exec -n $NS vault-0 -- vault secrets enable -path=secret kv-v2

echo "✅ Vault setup complete!"
echo "Root Token: $ROOT_TOKEN"
echo "Unseal Key: $UNSEAL_KEY"
echo ""
echo "Save cluster-keys.json in a secure location!"
```

Make it executable and run:
```bash
chmod +x setup-vault.sh
./setup-vault.sh
```

---

## Usage Examples

### Example 1: Create a Self-Signed Issuer

```yaml
# self-signed-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
```

Apply:
```bash
kubectl apply -f self-signed-issuer.yaml
```

### Example 2: Create a Certificate

```yaml
# app-certificate.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-app-tls
  namespace: default
spec:
  secretName: my-app-tls
  duration: 2160h # 90 days
  renewBefore: 360h # 15 days before expiry
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
  commonName: my-app.example.com
  dnsNames:
    - my-app.example.com
    - my-app.default.svc.cluster.local
```

Apply:
```bash
kubectl apply -f app-certificate.yaml

# Verify certificate
kubectl get certificate -n default
kubectl describe certificate my-app-tls -n default
```

### Example 3: Store Secrets in Vault

```bash
# Login to Vault
kubectl exec -n security -it vault-0 -- sh

# Inside the pod
vault login <root-token>

# Create a secret
vault kv put secret/myapp/config \
  database_url="postgres://user:pass@localhost:5432/db" \
  api_key="super-secret-key"

# Read it back
vault kv get secret/myapp/config
```

### Example 4: Create Vault Policy and Role

```bash
# Create policy
kubectl exec -n security vault-0 -- sh -c 'cat > /tmp/myapp-policy.hcl <<EOF
path "secret/data/myapp/*" {
  capabilities = ["read"]
}
EOF
vault policy write myapp /tmp/myapp-policy.hcl'

# Create role
kubectl exec -n security vault-0 -- vault write auth/kubernetes/role/myapp \
  bound_service_account_names=myapp \
  bound_service_account_namespaces=default \
  policies=myapp \
  ttl=24h
```

### Example 5: Deploy App with Vault Injection

```yaml
# app-deployment.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp
  namespace: default
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "myapp"
        vault.hashicorp.com/agent-inject-secret-config: "secret/data/myapp/config"
        vault.hashicorp.com/agent-inject-template-config: |
          {{- with secret "secret/data/myapp/config" -}}
          export DATABASE_URL="{{ .Data.data.database_url }}"
          export API_KEY="{{ .Data.data.api_key }}"
          {{- end }}
    spec:
      serviceAccountName: myapp
      containers:
      - name: app
        image: nginx:latest
        command: ["/bin/sh"]
        args: ["-c", "source /vault/secrets/config && nginx -g 'daemon off;'"]
```

Apply:
```bash
kubectl apply -f app-deployment.yaml

# Check that secrets are injected
kubectl exec -n default -it <pod-name> -- cat /vault/secrets/config
```

---

## Interaction Diagram

```
┌────────────────────────────────────────────────────────────────────────┐
│                         Complete Flow                                  │
└────────────────────────────────────────────────────────────────────────┘

1. Certificate Request Flow:
   ┌────────────┐      ┌──────────────┐      ┌─────────────┐
   │ Developer  │─────▶│ Cert-Manager │─────▶│ Certificate │
   │ (kubectl)  │      │ Controller   │      │  Secret     │
   └────────────┘      └──────────────┘      └─────────────┘
                              │
                              ▼
                       ┌──────────────┐
                       │ Vault Server │ (Optional: Store private keys)
                       └──────────────┘

2. Secret Access Flow:
   ┌────────────┐      ┌──────────────┐      ┌─────────────┐
   │ Pod Start  │─────▶│ Vault Agent  │─────▶│ Vault       │
   │            │      │ Injector     │      │ Server      │
   └────────────┘      └──────────────┘      └─────────────┘
                              │                      │
                              │                      │
                              ▼                      ▼
                       ┌──────────────────────────────┐
                       │ Sidecar Container (vault-    │
                       │ agent) Fetches & Renews      │
                       │ Secrets                      │
                       └──────────────────────────────┘
                              │
                              ▼
                       ┌──────────────┐
                       │ App Container│ Reads from
                       │ /vault/      │ /vault/secrets/
                       │ secrets/     │
                       └──────────────┘

3. TLS + Secrets Combined:
   ┌────────────────────────────────────────┐
   │           Application Pod              │
   ├────────────────────────────────────────┤
   │                                        │
   │  ┌─────────────────┐  ┌─────────────┐ │
   │  │ Vault Agent     │  │ App         │ │
   │  │ (Sidecar)       │  │ Container   │ │
   │  │                 │  │             │ │
   │  │ Injects:        │  │ Uses:       │ │
   │  │ - DB Password   │  │ - Secrets   │ │
   │  │ - API Keys      │  │ - TLS Cert  │ │
   │  └─────────────────┘  └─────────────┘ │
   │                                        │
   │  Volume Mounts:                        │
   │  - /vault/secrets/ (from Vault)        │
   │  - /tls/ (from cert-manager secret)    │
   │                                        │
   └────────────────────────────────────────┘
```

---

## Troubleshooting

### Cert-Manager Issues

**Problem**: Certificate not being issued

```bash
# Check certificate status
kubectl describe certificate <cert-name> -n <namespace>

# Check cert-manager logs
kubectl logs -n security -l app=cert-manager -f

# Check issuer status
kubectl describe issuer <issuer-name> -n <namespace>
```

**Problem**: Webhook not responding

```bash
# Check webhook logs
kubectl logs -n security -l app=cert-manager-webhook -f

# Restart webhook
kubectl rollout restart deployment cert-manager-webhook -n security
```

### Vault Issues

**Problem**: Vault pod not ready (sealed)

```bash
# Check seal status
kubectl exec -n security vault-0 -- vault status

# Unseal vault
kubectl exec -n security vault-0 -- vault operator unseal <unseal-key>
```

**Problem**: Agent injection not working

```bash
# Check injector logs
kubectl logs -n security -l app.kubernetes.io/name=vault-agent-injector -f

# Verify annotations on pod
kubectl describe pod <pod-name> -n <namespace>

# Check service account has permission
kubectl get sa <service-account> -n <namespace>
```

**Problem**: Cannot read secrets from Vault

```bash
# Test from inside vault pod
kubectl exec -n security -it vault-0 -- sh
vault login <root-token>
vault kv get secret/path/to/secret

# Check policy
vault policy read <policy-name>

# Check role binding
vault read auth/kubernetes/role/<role-name>
```

### Common Commands

```bash
# View all cert-manager resources
kubectl get certificates,certificaterequests,issuers -A

# View Vault status
kubectl exec -n security vault-0 -- vault status

# Check Raft cluster status
kubectl exec -n security vault-0 -- vault operator raft list-peers

# Re-unseal all vault pods after restart
UNSEAL_KEY="<your-unseal-key>"
kubectl exec -n security vault-0 -- vault operator unseal $UNSEAL_KEY
kubectl exec -n security vault-1 -- vault operator unseal $UNSEAL_KEY
kubectl exec -n security vault-2 -- vault operator unseal $UNSEAL_KEY

# Access Vault UI (port-forward)
kubectl port-forward -n security svc/vault 8200:8200
# Open: http://localhost:8200
```

---

## Quick Start Scripts

### Complete Setup for Kind

Save as `quick-setup-kind.sh`:

```bash
#!/bin/bash
set -e

echo "🚀 Setting up security stack on Kind..."

# Create cluster
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: security-demo
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 8200
    hostPort: 8200
- role: worker
- role: worker
EOF

# Create namespace
kubectl create namespace security

# Install cert-manager
echo "📜 Installing cert-manager..."
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace security \
  --version v1.13.2 \
  --set installCRDs=true \
  --wait

# Install Vault
echo "🔐 Installing Vault..."
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault \
  --namespace security \
  --set server.ha.enabled=true \
  --set server.ha.raft.enabled=true \
  --set server.ha.replicas=3 \
  --wait

echo "⏳ Waiting for pods to be ready..."
sleep 30

# Initialize Vault
echo "🔧 Initializing Vault..."
kubectl exec -n security vault-0 -- vault operator init \
  -key-shares=1 \
  -key-threshold=1 \
  -format=json > cluster-keys.json

UNSEAL_KEY=$(cat cluster-keys.json | jq -r ".unseal_keys_b64[0]")
ROOT_TOKEN=$(cat cluster-keys.json | jq -r ".root_token")

# Unseal all vault pods
echo "🔓 Unsealing Vault pods..."
kubectl exec -n security vault-0 -- vault operator unseal $UNSEAL_KEY
kubectl exec -n security vault-1 -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec -n security vault-1 -- vault operator unseal $UNSEAL_KEY
kubectl exec -n security vault-2 -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec -n security vault-2 -- vault operator unseal $UNSEAL_KEY

echo "✅ Setup complete!"
echo ""
echo "📝 Credentials saved to cluster-keys.json"
echo "🔑 Root Token: $ROOT_TOKEN"
echo "🔓 Unseal Key: $UNSEAL_KEY"
echo ""
echo "Access Vault UI: kubectl port-forward -n security svc/vault 8200:8200"
echo "Then open: http://localhost:8200"
```

Make it executable:
```bash
chmod +x quick-setup-kind.sh
./quick-setup-kind.sh
```

---

## Additional Resources

- [Cert-Manager Documentation](https://cert-manager.io/docs/)
- [HashiCorp Vault Documentation](https://developer.hashicorp.com/vault/docs)
- [Vault on Kubernetes Guide](https://developer.hashicorp.com/vault/tutorials/kubernetes)
- [Cert-Manager Tutorial](https://cert-manager.io/docs/tutorials/)

---

## Summary

| Component | Purpose | Pods | Dependencies |
|-----------|---------|------|--------------|
| **cert-manager** | Automated certificate management | 3 pods | None |
| **Vault** | Secrets management & encryption | 4 pods (3 servers + 1 injector) | None |

Both components work independently but complement each other:
- **cert-manager** handles TLS/SSL certificates
- **Vault** handles secrets (passwords, API keys, tokens)

Together they provide a complete security infrastructure for your Kubernetes cluster.


