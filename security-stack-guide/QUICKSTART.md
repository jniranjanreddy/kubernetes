# Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Option 1: Kind (Recommended for Development)

```bash
cd security-stack-guide

# Make scripts executable
chmod +x *.sh

# Run the setup script
./quick-setup-kind.sh

# Wait for completion (~3-5 minutes)
# Your cluster will be ready with cert-manager and Vault installed!
```

### Option 2: Minikube

```bash
cd security-stack-guide

# Make scripts executable
chmod +x *.sh

# Run the setup script
./quick-setup-minikube.sh

# Wait for completion (~3-5 minutes)
```

### Option 3: Existing Cluster (AKS, EKS, GKE)

```bash
cd security-stack-guide

# Make scripts executable
chmod +x *.sh

# Just setup Vault on existing cluster
./setup-vault-only.sh security

# Or specify different namespace
./setup-vault-only.sh my-namespace
```

---

## 📋 What You Get

After running the setup:

✅ **Cert-Manager** (3 pods)
- Controller for managing certificates
- CA Injector for injecting CA bundles
- Webhook for validating resources

✅ **Vault** (4 pods)
- 3 Vault servers in HA mode (Raft consensus)
- 1 Agent injector for automatic secret injection
- Pre-configured Kubernetes authentication
- KV secrets engine enabled

✅ **Configuration Files**
- `cluster-keys.json` - Your Vault credentials (KEEP SAFE!)
- Contains root token and unseal key

---

## 🔍 Verify Installation

```bash
# Check all pods are running
kubectl get pods -n security

# Expected output:
# NAME                                       READY   STATUS    RESTARTS   AGE
# cert-manager-*                             1/1     Running   0          2m
# cert-manager-cainjector-*                  1/1     Running   0          2m
# cert-manager-webhook-*                     1/1     Running   0          2m
# vault-0                                    1/1     Running   0          2m
# vault-1                                    1/1     Running   0          2m
# vault-2                                    1/1     Running   0          2m
# vault-agent-injector-*                     1/1     Running   0          2m

# Check Vault status
kubectl exec -n security vault-0 -- vault status

# Expected: Initialized: true, Sealed: false
```

---

## 🎯 Next Steps

### 1. Access Vault UI

```bash
# Start port forward (in background)
kubectl port-forward -n security svc/vault 8200:8200 &

# Open in browser
open http://localhost:8200

# Login with token from cluster-keys.json
cat cluster-keys.json | jq -r '.root_token'
```

### 2. Create Your First Certificate

```bash
# Apply the example
kubectl apply -f examples/certificate-example.yaml

# Check certificate status
kubectl get certificate myapp-tls -n default

# View the secret
kubectl get secret myapp-tls -n default -o yaml
```

### 3. Deploy App with Vault Secrets

```bash
# First, configure Vault
./examples/vault-setup-commands.sh

# Deploy the example app
kubectl apply -f examples/vault-app-example.yaml

# Check that secrets are injected
POD=$(kubectl get pod -n default -l app=myapp-vault -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n default -it $POD -c app -- cat /vault/secrets/database
```

---

## 📚 Learn More

- **[README.md](README.md)** - Full documentation with detailed explanations
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Architecture diagrams and data flows
- **[examples/](examples/)** - More example configurations

---

## 🔧 Common Commands

### Cert-Manager

```bash
# List all certificates
kubectl get certificates -A

# Describe a certificate
kubectl describe certificate <name> -n <namespace>

# Check cert-manager logs
kubectl logs -n security -l app=cert-manager -f

# Force certificate renewal
kubectl annotate certificate <name> -n <namespace> \
  cert-manager.io/issue-temporary-certificate="true" --overwrite
```

### Vault

```bash
# Check seal status
kubectl exec -n security vault-0 -- vault status

# List secrets
kubectl exec -n security vault-0 -- vault kv list secret/

# Read a secret
kubectl exec -n security vault-0 -- vault kv get secret/path/to/secret

# Create a secret
kubectl exec -n security vault-0 -- vault kv put secret/myapp/config \
  key1=value1 key2=value2

# List policies
kubectl exec -n security vault-0 -- vault policy list

# List roles
kubectl exec -n security vault-0 -- vault list auth/kubernetes/role
```

### Troubleshooting

```bash
# Vault pod not ready? Check if sealed
kubectl exec -n security vault-0 -- vault status
# If sealed, unseal with key from cluster-keys.json
UNSEAL_KEY=$(cat cluster-keys.json | jq -r '.unseal_keys_b64[0]')
kubectl exec -n security vault-0 -- vault operator unseal $UNSEAL_KEY

# Certificate not issuing?
kubectl describe certificate <name> -n <namespace>
kubectl logs -n security -l app=cert-manager -f

# Vault secrets not injecting?
kubectl logs -n security -l app.kubernetes.io/name=vault-agent-injector -f
kubectl describe pod <pod-name> -n <namespace>
```

---

## 🧹 Cleanup

### Remove Everything

```bash
# For Kind
kind delete cluster --name security-demo

# For Minikube
minikube delete

# For existing cluster (keep cluster, remove apps)
helm uninstall vault -n security
helm uninstall cert-manager -n security
kubectl delete namespace security
```

### Remove Just the Examples

```bash
kubectl delete -f examples/certificate-example.yaml
kubectl delete -f examples/vault-app-example.yaml
```

---

## 💡 Tips

1. **Save your credentials!**
   - `cluster-keys.json` contains your root token and unseal key
   - Store it securely (password manager, encrypted storage)
   - You'll need it after cluster restarts

2. **Vault starts sealed after restart**
   - After pod restart, Vault is sealed
   - Run: `kubectl exec -n security vault-0 -- vault operator unseal <key>`
   - Consider auto-unseal with cloud KMS for production

3. **Certificate renewal**
   - Cert-manager automatically renews certificates
   - Default: 15 days before expiry
   - Monitor with: `kubectl get certificates -A`

4. **Production checklist**
   - Use proper CA (Let's Encrypt, private CA)
   - Enable Vault audit logging
   - Implement RBAC policies
   - Set up monitoring/alerts
   - Use auto-unseal for Vault
   - Regular backups

---

## 🆘 Getting Help

- Check logs: `kubectl logs -n security <pod-name>`
- Check events: `kubectl get events -n security --sort-by='.lastTimestamp'`
- Describe resources: `kubectl describe <resource> <name> -n <namespace>`
- Read the docs: [README.md](README.md) and [ARCHITECTURE.md](ARCHITECTURE.md)

---

## 📝 What's in cluster-keys.json?

```json
{
  "unseal_keys_b64": ["<unseal-key>"],
  "unseal_keys_hex": ["<unseal-key-hex>"],
  "unseal_shares": 1,
  "unseal_threshold": 1,
  "recovery_keys_b64": [],
  "recovery_keys_hex": [],
  "recovery_keys_shares": 0,
  "recovery_keys_threshold": 0,
  "root_token": "<root-token>"
}
```

**Important values:**
- `unseal_keys_b64[0]` - Use to unseal Vault after restart
- `root_token` - Use to login to Vault (has full admin access)

**⚠️ SECURITY WARNING:**
Never commit this file to git! Add to `.gitignore`:
```bash
echo "cluster-keys.json" >> .gitignore
```

---

Happy securing! 🔐

