#!/bin/bash
# Commands to configure Vault for the example application

set -e

NS="security"
ROOT_TOKEN="<your-root-token>"

echo "🔐 Configuring Vault for myapp..."

# Login to Vault
kubectl exec -n $NS vault-0 -- vault login $ROOT_TOKEN

# Create secrets
echo "📦 Creating secrets..."
kubectl exec -n $NS vault-0 -- vault kv put secret/myapp/database \
  host="postgres.default.svc.cluster.local" \
  port="5432" \
  username="myapp_user" \
  password="super-secret-password" \
  database="myapp_db"

kubectl exec -n $NS vault-0 -- vault kv put secret/myapp/api \
  key="pk_live_1234567890abcdef" \
  secret="sk_live_0987654321fedcba"

# Create policy
echo "📋 Creating policy..."
kubectl exec -n $NS vault-0 -- sh -c 'cat > /tmp/myapp-policy.hcl <<EOF
path "secret/data/myapp/*" {
  capabilities = ["read", "list"]
}
EOF
vault policy write myapp /tmp/myapp-policy.hcl'

# Create Kubernetes role
echo "🔑 Creating Kubernetes role..."
kubectl exec -n $NS vault-0 -- vault write auth/kubernetes/role/myapp \
  bound_service_account_names=myapp \
  bound_service_account_namespaces=default \
  policies=myapp \
  ttl=24h

echo "✅ Vault configuration complete!"
echo ""
echo "📋 Verify:"
echo "  kubectl exec -n $NS vault-0 -- vault kv get secret/myapp/database"
echo "  kubectl exec -n $NS vault-0 -- vault policy read myapp"
echo "  kubectl exec -n $NS vault-0 -- vault read auth/kubernetes/role/myapp"
echo ""
echo "🚀 Deploy the app:"
echo "  kubectl apply -f examples/vault-app-example.yaml"

