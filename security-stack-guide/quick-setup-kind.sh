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
    protocol: TCP
  - containerPort: 30443
    hostPort: 30443
    protocol: TCP
- role: worker
  labels:
    node-id: worker1
- role: worker
  labels:
    node-id: worker2
- role: worker
  labels:
    node-id: worker3
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

# Enable Kubernetes auth
echo "🔑 Configuring Kubernetes authentication..."
kubectl exec -n security vault-0 -- vault login $ROOT_TOKEN
kubectl exec -n security vault-0 -- vault auth enable kubernetes
kubectl exec -n security vault-0 -- sh -c 'vault write auth/kubernetes/config \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"'

# Enable KV secrets engine
echo "📦 Enabling KV secrets engine..."
kubectl exec -n security vault-0 -- vault secrets enable -path=secret kv-v2

echo ""
echo "✅ Setup complete!"
echo ""
echo "📝 Credentials saved to cluster-keys.json"
echo "🔑 Root Token: $ROOT_TOKEN"
echo "🔓 Unseal Key: $UNSEAL_KEY"
echo ""
echo "🌐 Access Vault UI:"
echo "   kubectl port-forward -n security svc/vault 8200:8200"
echo "   Then open: http://localhost:8200"
echo ""
echo "📊 Check status:"
echo "   kubectl get pods -n security"
echo "   kubectl exec -n security vault-0 -- vault status"

