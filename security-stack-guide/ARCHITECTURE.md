# Security Stack Architecture

## High-Level Architecture

```
┌───────────────────────────────────────────────────────────────────────────┐
│                         Kubernetes Cluster                                │
├───────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                      Security Namespace                             │  │
│  ├─────────────────────────────────────────────────────────────────────┤  │
│  │                                                                       │  │
│  │  ┌──────────────────────────┐    ┌──────────────────────────┐      │  │
│  │  │     Cert-Manager         │    │     HashiCorp Vault      │      │  │
│  │  │                          │    │                          │      │  │
│  │  │  ┌────────────────────┐  │    │  ┌────────────────────┐ │      │  │
│  │  │  │  Controller        │  │    │  │  Vault Servers     │ │      │  │
│  │  │  │  - Watches CRDs    │  │    │  │  ┌──────────────┐  │ │      │  │
│  │  │  │  - Issues certs    │  │    │  │  │  vault-0     │  │ │      │  │
│  │  │  │  - Renews certs    │  │    │  │  │  (Leader)    │  │ │      │  │
│  │  │  └────────────────────┘  │    │  │  └──────────────┘  │ │      │  │
│  │  │                          │    │  │  ┌──────────────┐  │ │      │  │
│  │  │  ┌────────────────────┐  │    │  │  │  vault-1     │  │ │      │  │
│  │  │  │  CA Injector       │  │    │  │  │  (Follower)  │  │ │      │  │
│  │  │  │  - Injects CA      │  │    │  │  └──────────────┘  │ │      │  │
│  │  │  │    bundles         │  │    │  │  ┌──────────────┐  │ │      │  │
│  │  │  └────────────────────┘  │    │  │  │  vault-2     │  │ │      │  │
│  │  │                          │    │  │  │  (Follower)  │  │ │      │  │
│  │  │  ┌────────────────────┐  │    │  │  └──────────────┘  │ │      │  │
│  │  │  │  Webhook           │  │    │  │                    │ │      │  │
│  │  │  │  - Validates       │  │    │  │  Raft Consensus    │ │      │  │
│  │  │  │    resources       │  │    │  │  (HA Storage)      │ │      │  │
│  │  │  └────────────────────┘  │    │  └────────────────────┘ │      │  │
│  │  │                          │    │                          │      │  │
│  │  │  API: cert-manager.io   │    │  ┌────────────────────┐ │      │  │
│  │  │  - Certificate          │    │  │  Agent Injector    │ │      │  │
│  │  │  - Issuer               │    │  │  - Mutates pods    │ │      │  │
│  │  │  - ClusterIssuer        │    │  │  - Adds sidecars   │ │      │  │
│  │  │  - CertificateRequest   │    │  │  - Injects secrets │ │      │  │
│  │  └──────────────────────────┘    │  └────────────────────┘ │      │  │
│  │                                   │                          │      │  │
│  │                                   │  API: 8200/TCP           │      │  │
│  │                                   │  Storage: Raft           │      │  │
│  │                                   └──────────────────────────┘      │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                      Application Namespaces                         │  │
│  ├─────────────────────────────────────────────────────────────────────┤  │
│  │                                                                       │  │
│  │  ┌────────────────────────────────────────────────────────────────┐ │  │
│  │  │                     Application Pod                            │ │  │
│  │  ├────────────────────────────────────────────────────────────────┤ │  │
│  │  │                                                                  │ │  │
│  │  │  ┌──────────────────┐          ┌──────────────────┐           │ │  │
│  │  │  │  Vault Agent     │          │  App Container   │           │ │  │
│  │  │  │  (Init + Sidecar)│          │                  │           │ │  │
│  │  │  │                  │          │  Reads from:     │           │ │  │
│  │  │  │  - Auth to Vault │          │  /vault/secrets/ │           │ │  │
│  │  │  │  - Fetch secrets │          │                  │           │ │  │
│  │  │  │  - Auto-renew    │          │  Uses TLS from:  │           │ │  │
│  │  │  │  - Template      │          │  /etc/tls/       │           │ │  │
│  │  │  └──────────────────┘          └──────────────────┘           │ │  │
│  │  │           │                              │                      │ │  │
│  │  │           └──────────────────────────────┘                      │ │  │
│  │  │                  Shared Volume Mounts                           │ │  │
│  │  │                                                                  │ │  │
│  │  │  Volume Mounts:                                                 │ │  │
│  │  │  - /vault/secrets/ (EmptyDir - injected by vault-agent)        │ │  │
│  │  │  - /etc/tls/ (Secret - created by cert-manager)                │ │  │
│  │  │                                                                  │ │  │
│  │  └────────────────────────────────────────────────────────────────┘ │  │
│  │                                                                       │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
└───────────────────────────────────────────────────────────────────────────┘
```

## Data Flow

### Certificate Provisioning Flow

```
Developer                Cert-Manager           Certificate Authority         Application
    │                         │                          │                        │
    │  1. Create Certificate  │                          │                        │
    │  Resource (YAML)        │                          │                        │
    ├────────────────────────▶│                          │                        │
    │                         │                          │                        │
    │                         │  2. Generate CSR         │                        │
    │                         │  (Certificate Signing    │                        │
    │                         │   Request)               │                        │
    │                         ├─────────────────────────▶│                        │
    │                         │                          │                        │
    │                         │  3. Sign & Return Cert   │                        │
    │                         │◀─────────────────────────┤                        │
    │                         │                          │                        │
    │                         │  4. Store in K8s Secret  │                        │
    │                         │  (tls.crt, tls.key)      │                        │
    │                         ├──────────────────────────┼───────────────────────▶│
    │                         │                          │                        │
    │                         │  5. Mount Secret         │                        │
    │                         │     in Pod               │                        │
    │                         │                          │                        │
    │                         │  6. Auto-Renew           │                        │
    │                         │  (before expiry)         │                        │
    │                         ├─────────────────────────▶│                        │
    │                         │◀─────────────────────────┤                        │
    │                         │                          │                        │
```

### Secret Injection Flow (Vault)

```
Application Pod          Vault Agent            Vault Server           Kubernetes API
    │                       │                         │                      │
    │  1. Pod Created       │                         │                      │
    │  with Vault           │                         │                      │
    │  Annotations          │                         │                      │
    ├──────────────────────▶│                         │                      │
    │                       │                         │                      │
    │                       │  2. Mutating Webhook    │                      │
    │                       │  Injects vault-agent    │                      │
    │                       │  Init + Sidecar         │                      │
    │◀──────────────────────┤                         │                      │
    │                       │                         │                      │
    │  3. Init: Auth with   │                         │                      │
    │  Service Account      │                         │                      │
    │  JWT Token            │                         │                      │
    │                       ├────────────────────────▶│                      │
    │                       │                         │                      │
    │                       │                         │  4. Verify JWT       │
    │                       │                         ├─────────────────────▶│
    │                       │                         │◀─────────────────────┤
    │                       │                         │                      │
    │                       │  5. Return Vault Token  │                      │
    │                       │◀────────────────────────┤                      │
    │                       │                         │                      │
    │                       │  6. Fetch Secrets       │                      │
    │                       ├────────────────────────▶│                      │
    │                       │◀────────────────────────┤                      │
    │                       │                         │                      │
    │  7. Write to          │                         │                      │
    │  /vault/secrets/      │                         │                      │
    │◀──────────────────────┤                         │                      │
    │                       │                         │                      │
    │  8. App Reads Secrets │                         │                      │
    │  from /vault/secrets/ │                         │                      │
    │                       │                         │                      │
    │                       │  9. Sidecar: Auto-Renew │                      │
    │                       │  (Background Process)   │                      │
    │                       ├────────────────────────▶│                      │
    │                       │◀────────────────────────┤                      │
    │                       │                         │                      │
```

## Component Interactions

### Cert-Manager Internal Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                        Cert-Manager                            │
├────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐   │
│  │              Controller Manager                        │   │
│  ├────────────────────────────────────────────────────────┤   │
│  │                                                          │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │   │
│  │  │ Certificate  │  │   Issuer     │  │  Challenge   │ │   │
│  │  │ Controller   │  │  Controller  │  │  Controller  │ │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘ │   │
│  │         │                  │                  │         │   │
│  │         └──────────────────┼──────────────────┘         │   │
│  │                            │                            │   │
│  │                            ▼                            │   │
│  │                   ┌────────────────┐                   │   │
│  │                   │  Kubernetes    │                   │   │
│  │                   │  API Server    │                   │   │
│  │                   └────────────────┘                   │   │
│  └────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐   │
│  │              CA Injector                               │   │
│  ├────────────────────────────────────────────────────────┤   │
│  │  Watches: ValidatingWebhookConfiguration              │   │
│  │           MutatingWebhookConfiguration                │   │
│  │           APIServices                                  │   │
│  │                                                          │   │
│  │  Injects: CA bundles from Certificates                │   │
│  └────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐   │
│  │              Webhook                                   │   │
│  ├────────────────────────────────────────────────────────┤   │
│  │  Validates: Certificate, Issuer, ClusterIssuer        │   │
│  │  Mutates: (if configured)                             │   │
│  └────────────────────────────────────────────────────────┘   │
│                                                                  │
└────────────────────────────────────────────────────────────────┘
```

### Vault Internal Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                      HashiCorp Vault Cluster                   │
├────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐  │
│  │   vault-0    │     │   vault-1    │     │   vault-2    │  │
│  │   (Leader)   │◀───▶│  (Follower)  │◀───▶│  (Follower)  │  │
│  └──────────────┘     └──────────────┘     └──────────────┘  │
│         │                     │                     │          │
│         └─────────────────────┼─────────────────────┘          │
│                               │                                │
│                               ▼                                │
│                      ┌────────────────┐                       │
│                      │  Raft Storage  │                       │
│                      │  (Consensus)   │                       │
│                      └────────────────┘                       │
│                               │                                │
│                               ▼                                │
│                      ┌────────────────┐                       │
│                      │  Persistent    │                       │
│                      │  Volume Claims │                       │
│                      │  (PVC)         │                       │
│                      └────────────────┘                       │
│                                                                  │
│  API Endpoints:                                                 │
│  - /v1/sys/*     (System operations)                           │
│  - /v1/auth/*    (Authentication)                              │
│  - /v1/secret/*  (KV Secrets)                                  │
│  - /v1/sys/seal-status (Seal status)                           │
│                                                                  │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│                   Vault Agent Injector                         │
├────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Mutating Admission Webhook                                     │
│  Watches: Pod creation in all namespaces                       │
│                                                                  │
│  When pod has vault.hashicorp.com/* annotations:               │
│  1. Injects init container (vault-agent-init)                 │
│  2. Injects sidecar container (vault-agent)                   │
│  3. Creates shared volume (EmptyDir)                           │
│  4. Configures vault-agent config                             │
│                                                                  │
└────────────────────────────────────────────────────────────────┘
```

## Authentication & Authorization

### Vault Kubernetes Auth Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                   Kubernetes Authentication                         │
└─────────────────────────────────────────────────────────────────────┘

1. Pod starts with ServiceAccount
   │
   │  ServiceAccount JWT automatically mounted at:
   │  /var/run/secrets/kubernetes.io/serviceaccount/token
   │
   ▼
2. Vault Agent reads JWT
   │
   │  POST /v1/auth/kubernetes/login
   │  {
   │    "role": "myapp",
   │    "jwt": "<service-account-jwt>"
   │  }
   │
   ▼
3. Vault validates JWT with Kubernetes API
   │
   │  TokenReview API call to verify:
   │  - JWT signature is valid
   │  - ServiceAccount exists
   │  - Matches configured role bindings
   │
   ▼
4. Vault checks role configuration
   │
   │  bound_service_account_names: [myapp]
   │  bound_service_account_namespaces: [default]
   │  policies: [myapp]
   │
   ▼
5. Vault returns token
   │
   │  {
   │    "auth": {
   │      "client_token": "hvs.xxxxx",
   │      "policies": ["default", "myapp"],
   │      "renewable": true,
   │      "ttl": 86400
   │    }
   │  }
   │
   ▼
6. Agent uses token to fetch secrets
   │
   │  GET /v1/secret/data/myapp/config
   │  Header: X-Vault-Token: hvs.xxxxx
   │
   ▼
7. Secrets written to /vault/secrets/
```

### Cert-Manager Certificate Lifecycle

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Certificate Lifecycle                            │
└─────────────────────────────────────────────────────────────────────┘

State: Pending
   │
   │  Certificate resource created
   │
   ▼
State: Issuing
   │
   │  1. Generate private key
   │  2. Create CertificateRequest
   │  3. Submit CSR to Issuer
   │
   ▼
State: Ready
   │
   │  Certificate stored in Secret:
   │  - tls.crt (certificate)
   │  - tls.key (private key)
   │  - ca.crt (CA certificate)
   │
   │  Certificate mounted in Pod
   │
   ▼
State: Ready (Monitoring)
   │
   │  Cert-Manager watches expiry
   │  renewBefore: 15 days
   │
   ▼
State: Renewing (15 days before expiry)
   │
   │  1. Generate new CSR
   │  2. Request new certificate
   │  3. Update Secret
   │  4. Pods pick up new cert
   │
   ▼
State: Ready (New certificate)
```

## Security Considerations

### Vault Security Model

```
┌────────────────────────────────────────────────────────────┐
│                    Vault Security Layers                   │
├────────────────────────────────────────────────────────────┤
│                                                              │
│  Layer 1: Seal/Unseal                                       │
│  ├─ Vault starts "sealed" (encrypted at rest)              │
│  ├─ Requires unseal key(s) to decrypt                      │
│  └─ Master key never stored on disk                        │
│                                                              │
│  Layer 2: Authentication                                    │
│  ├─ Multiple auth methods (K8s, LDAP, GitHub, etc)        │
│  ├─ Each client must authenticate                          │
│  └─ Receives time-limited token                            │
│                                                              │
│  Layer 3: Authorization (Policies)                         │
│  ├─ Path-based access control                              │
│  ├─ Capabilities: create, read, update, delete, list      │
│  └─ Deny by default                                        │
│                                                              │
│  Layer 4: Audit Logging                                    │
│  ├─ All requests/responses logged                          │
│  ├─ Includes auth attempts, secret access                  │
│  └─ Sent to file, syslog, or external systems             │
│                                                              │
│  Layer 5: Encryption                                        │
│  ├─ Data encrypted at rest (using master key)             │
│  ├─ TLS for data in transit                                │
│  └─ Encryption as a service (Transit engine)              │
│                                                              │
└────────────────────────────────────────────────────────────┘
```

### Best Practices

1. **Vault**
   - Store unseal keys and root token securely (not in cluster)
   - Use auto-unseal with cloud KMS in production
   - Enable audit logging
   - Rotate tokens regularly
   - Use AppRole or K8s auth (not root token)
   - Implement least privilege policies

2. **Cert-Manager**
   - Use separate issuers for different environments
   - Set appropriate renewal periods (renewBefore)
   - Monitor certificate expiry
   - Use ClusterIssuers for cluster-wide certificates
   - Implement RBAC for certificate resources

3. **Integration**
   - Use cert-manager to provision TLS for Vault
   - Store TLS keys in Vault for additional security
   - Separate namespaces for security infrastructure
   - Implement network policies
   - Regular backup of Vault data and cert-manager CRDs

## Monitoring & Observability

### Key Metrics

**Cert-Manager:**
- Certificate expiry time
- Certificate renewal success/failure rate
- ACME challenge success rate
- Controller reconciliation time

**Vault:**
- Seal status
- Token usage
- Secret access patterns
- Authentication failures
- Raft cluster health
- Storage usage

### Health Checks

```bash
# Cert-Manager health
kubectl get certificates -A
kubectl get certificaterequests -A
kubectl logs -n security -l app=cert-manager

# Vault health
kubectl exec -n security vault-0 -- vault status
kubectl exec -n security vault-0 -- vault operator raft list-peers
kubectl logs -n security -l app.kubernetes.io/name=vault
```

