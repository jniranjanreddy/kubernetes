#!/bin/bash
# Script to initialize and unseal an existing Vault installation

set -e

NS="${1:-security}"

echo "🔧 Setting up Vault in namespace: $NS"

# Wait for vault-0 to be running
echo "⏳ Waiting for vault-0 to be running..."
kubectl wait --for=condition=ready pod/vault-0 -n $NS --timeout=300s 2>/dev/null || \
  (echo "Waiting manually..." && sleep 30)

# Check if already initialized
if kubectl exec -n $NS vault-0 -- vault status 2>/dev/null | grep -q "Initialized.*true"; then
  echo "⚠️  Vault is already initialized!"
  echo "If you need to unseal, run:"
  echo "  kubectl exec -n $NS vault-0 -- vault operator unseal <unseal-key>"
  exit 0
fi

# Initialize Vault
echo "🔧 Initializing Vault..."
kubectl exec -n $NS vault-0 -- vault operator init \
  -key-shares=1 \
  -key-threshold=1 \
  -format=json > cluster-keys.json

# Extract keys
CONTENT=$(tr -d '\n\r\t ' < cluster-keys.json)
UNSEAL_KEY=$(printf '%s' "$CONTENT" | sed -n -E 's/.*"unseal_keys_b64":\["([^"]*)".*/\1/p')
ROOT_TOKEN=$(printf '%s' "$CONTENT" | sed -n -E 's/.*"root_token":"([^"]*)".*/\1/p')

echo "🔓 Unsealing vault-0..."
kubectl exec -n $NS vault-0 -- vault operator unseal $UNSEAL_KEY

echo "🔑 Logging into vault-0..."
kubectl exec -n $NS vault-0 -- vault login $ROOT_TOKEN

# Join and unseal remaining pods
for i in 1 2; do
  echo "🔗 Joining vault-$i to Raft cluster..."
  kubectl exec -n $NS vault-$i -- vault operator raft join http://vault-0.vault-internal:8200 || true
  
  echo "🔓 Unsealing vault-$i..."
  kubectl exec -n $NS vault-$i -- vault operator unseal $UNSEAL_KEY
done

echo "📋 Listing Raft peers..."
kubectl exec -n $NS vault-0 -- vault operator raft list-peers

echo "🔑 Enabling Kubernetes auth..."
kubectl exec -n $NS vault-0 -- vault auth enable kubernetes 2>/dev/null || \
  echo "Kubernetes auth already enabled"

echo "⚙️  Configuring Kubernetes auth..."
kubectl exec -n $NS vault-0 -- sh -c 'vault write auth/kubernetes/config \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"'

echo "📦 Enabling KV secrets engine..."
kubectl exec -n $NS vault-0 -- vault secrets enable -path=secret kv-v2 2>/dev/null || \
  echo "KV secrets engine already enabled"

echo ""
echo "✅ Vault setup complete!"
echo ""
echo "📝 Credentials:"
echo "   File: cluster-keys.json"
echo "   Root Token: $ROOT_TOKEN"
echo "   Unseal Key: $UNSEAL_KEY"
echo ""
echo "⚠️  IMPORTANT: Save cluster-keys.json in a secure location!"
echo ""
echo "🔍 Verify status:"
echo "   kubectl get pods -n $NS"
echo "   kubectl exec -n $NS vault-0 -- vault status"

