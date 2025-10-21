# Vault

```
🧩 1. What is HashiCorp Vault?

Answer:
HashiCorp Vault is a tool for securely storing, accessing, and managing sensitive information (like passwords, API keys, tokens, and certificates). It provides a unified interface to secrets with tight access control and audit logging.
Vault can also generate dynamic credentials, encrypt data, and control access via policies.

⚙️ 2. What are the main use cases of Vault?

Answer:

Secret management (API keys, DB passwords)

Dynamic secrets (auto-generated credentials for DBs or cloud providers)

Encryption-as-a-Service (encrypt/decrypt without storing data)

Identity-based access control

Secure introduction and secret rotation

🔐 3. Explain Vault’s architecture.

Answer:

Client: Sends API or CLI requests.

Server: Processes the request, stores data encrypted.

Storage Backend: Stores encrypted data (e.g., Raft, Consul, Azure Blob).

Seal/Unseal Keys: Used to encrypt/decrypt the master key.

Secret Engines: Manage different types of secrets.

Auth Methods: Verify identity (e.g., AppRole, Kubernetes, OIDC).

🧱 4. What is the seal/unseal process?

Answer:
When Vault starts, it is sealed — meaning the encryption key is locked.
To access data, you must unseal it by providing key shares (from Shamir’s secret sharing).
Once unsealed, Vault loads the master key into memory.

You can automate unsealing using Auto-Unseal with cloud KMS (like Azure Key Vault or AWS KMS).

🪪 5. What is the Root Token?

Answer:
It’s the initial administrative token created when Vault is initialized. It has full permissions.
For security, it should be revoked or stored securely after creating other admin tokens and policies.

🔑 6. What are Secret Engines?

Answer:
Secret Engines are components that store, generate, or encrypt secrets.
Examples:

kv/ → Key-Value store (static secrets)

database/ → Dynamic DB credentials

aws/ → Dynamic AWS IAM credentials

transit/ → Encryption-as-a-Service

pki/ → Issue SSL/TLS certificates

🧮 7. What’s the difference between KV v1 and KV v2?

Answer:

KV v1: No versioning; each secret overwrite replaces the old one.

KV v2: Supports versioning, metadata (created_time, version), and soft delete/restore.

🧰 8. What are Authentication Methods in Vault?

Answer:
Auth methods verify who or what is making a request. Examples:

userpass → Username/password

approle → For apps (uses RoleID + SecretID)

kubernetes → Authenticates service accounts in pods

oidc / azure → For federated identity (Azure AD, Okta)

token → Direct access token

👥 9. What is an AppRole and how does it work?

Answer:
AppRole is a machine-authentication method used by apps or automation.

It uses two credentials: RoleID (public) and SecretID (private).

The app authenticates with both and receives a Vault token with limited access.

It’s useful for CI/CD or headless apps needing secrets.

☸️ 10. How does Kubernetes authentication work in Vault?

Answer:

Vault is configured with a Kubernetes auth method.

Each pod uses its service account token to authenticate.

Vault verifies the JWT token with Kubernetes API.

If valid, Vault issues a Vault token mapped to a Vault policy.

Commonly used with Vault Agent Injector to inject secrets into pods as env vars or files.

🪄 11. What is the Transit Secrets Engine?

Answer:
It’s used for encryption-as-a-service — encrypt/decrypt data without storing it in Vault.

Useful when applications need cryptographic operations but don’t want to manage keys.

Example: encrypting SSNs before storing them in a database.

🧠 12. What are dynamic secrets?

Answer:
Dynamic secrets are generated on-demand with a limited TTL (time-to-live).
Example: when a client requests a DB credential, Vault creates a temporary username/password in the database that expires automatically.
→ Reduces secret leakage and rotation effort.

📜 13. What are Vault policies?

Answer:
Policies define who can access what in Vault using ACL syntax.
Example:

path "secret/data/project/*" {
  capabilities = ["read", "list"]
}


Users/tokens get permissions via policies, ensuring least privilege access.

🧾 14. How do leases and renewals work?

Answer:
When Vault issues a dynamic secret, it comes with a lease ID and TTL.

The client can renew before expiry.

When expired, Vault automatically revokes the secret (e.g., deletes DB user).

🧱 15. What storage backends can Vault use?

Answer:

Raft (integrated, recommended for HA)

Consul

Azure Blob Storage

S3

Google Cloud Storage

File system (for testing)

☁️ 16. How does Auto-Unseal work with Azure Key Vault?

Answer:
Instead of manually entering key shares, Vault uses Azure Key Vault’s KMS to automatically decrypt the master key during startup.
This simplifies restarts and HA setups in AKS or Azure VMs.

🧩 17. How can you inject secrets into Kubernetes pods securely?

Answer:
Using the Vault Agent Injector (sidecar pattern):

A sidecar container authenticates with Vault (via service account JWT).

It fetches secrets and writes them to shared memory or volume.

The main app reads secrets without direct access to Vault.

🧮 18. What are audit devices in Vault?

Answer:
Audit devices log all requests and responses (excluding sensitive data).
Examples:

file (local file logs)

syslog

socket
Audit logs include token ID, path, operation type — useful for compliance and investigations.

🧰 19. How do you monitor Vault health?

Answer:

vault status or /sys/health API endpoint

Prometheus metrics from /v1/sys/metrics

Integration with Azure Monitor / Grafana

Log-based alerts for seal events or unseal failures

⚡ 20. How do you backup and restore Vault?

Answer:

Use Vault Operator Snapshot (vault operator raft snapshot save)

Store the snapshot securely (Azure Blob, S3, etc.)

Restore using vault operator raft snapshot restore

Snapshots capture the Raft storage state.

🧩 21. What’s the difference between DR and Performance Replication?

Answer:

DR Replication: For disaster recovery (passive standby). Only activated if primary fails.

Performance Replication: For load balancing and low-latency read operations across regions.

🧮 22. How do you revoke a secret or token immediately?

Answer:

To revoke a token:

vault token revoke <token>


To revoke all secrets under a lease:

vault lease revoke <lease_id>


To revoke everything issued to a token:

vault token revoke -force <accessor>

🧠 23. How do you integrate Vault with Azure AD (OIDC)?

Answer:

Enable OIDC auth method (vault auth enable oidc).

Configure with Azure AD App (client ID, secret, redirect URI).

Map OIDC roles → Vault policies.

This allows Azure AD users to login to Vault using SSO.

☸️ 24. How do you deploy Vault in AKS (Azure Kubernetes Service)?

Answer:

Use the official HashiCorp Helm chart:

helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault --set "server.ha.enabled=true"


Configure storage backend (Raft or Azure Blob).

Enable Auto-Unseal with Azure Key Vault.

Expose with Azure Application Gateway ingress.

Configure Kubernetes auth method for app pods.

🚀 25. What are some best practices for securing Vault?

Answer:
✅ Enable audit logs
✅ Use short TTLs for tokens/secrets
✅ Enable auto-unseal with KMS
✅ Use policies with least privilege
✅ Regularly rotate root and unseal keys
✅ Enable TLS everywhere
✅ Integrate with SIEM (Azure Sentinel / Splunk)
✅ Limit Vault network access via firewalls or VNet
```
  ## scenario
  ```
  . Scenario: How would you design a Highly Available (HA) Vault setup in Azure?

Answer:
A production-grade HA setup in Azure should include:

Storage backend:
Use Integrated Storage (Raft) — built-in HA and replication.
Alternatively, Azure Blob storage (for open-source) or Consul.

Auto-Unseal:
Integrate with Azure Key Vault (AKV) for automatic unseal during restarts.

Deployment:

Deploy Vault in Azure Kubernetes Service (AKS) or VM Scale Sets.

Use Helm chart for multi-replica deployment.

Networking:

Use Azure Private Link for internal access.

Expose via Azure Application Gateway + TLS certs.

Monitoring:

Export Prometheus metrics to Azure Monitor/Grafana.

Disaster Recovery:

Enable Vault Enterprise DR Replication or schedule Raft snapshots to Azure Blob.

☸️ 2. How would you integrate Vault with Kubernetes to supply secrets to pods?

Answer:
Two common methods:

(a) Vault Agent Injector (Recommended):

Deploy Vault with vault-agent-injector in the cluster.

Annotate the pod with:

vault.hashicorp.com/agent-inject: "true"
vault.hashicorp.com/role: "app-role"
vault.hashicorp.com/agent-inject-secret-config: "secret/data/app/config"


The sidecar authenticates to Vault using Kubernetes service account and writes secrets to /vault/secrets.

(b) Vault CSI Driver:

Pods mount secrets via CSI volume:

volumeMounts:
- name: vault-secrets
  mountPath: "/mnt/secrets"
volumes:
- name: vault-secrets
  csi:
    driver: secrets.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: "vault-provider"


✅ Best practice: Use short TTLs and dynamic secrets wherever possible.

⚙️ 3. Scenario: You want to rotate database credentials automatically every 24 hours. How would you configure it?

Answer:

Enable the database secrets engine:

vault secrets enable database


Configure the database connection:

vault write database/config/mydb \
    plugin_name=mysql-database-plugin \
    connection_url="{{username}}:{{password}}@tcp(db.example.com:3306)/" \
    username="admin" password="adminpass"


Create a role with TTLs:

vault write database/roles/readonly \
    db_name=mydb \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}'; GRANT SELECT ON *.* TO '{{name}}'@'%';" \
    default_ttl=1h max_ttl=24h


Configure a periodic rotation job (or use Vault’s built-in lease expiration).

When TTL expires → Vault revokes old credentials → auto-rotates new ones.

🪪 4. Scenario: How do you integrate Vault into a CI/CD pipeline (e.g., GitHub Actions)?

Answer:

Configure AppRole or OIDC-based authentication for the CI runner.

In GitHub Actions:

- name: Authenticate to Vault
  run: |
    export VAULT_ADDR=https://vault.example.com
    vault login -method=approle role_id=$ROLE_ID secret_id=$SECRET_ID
- name: Fetch Secrets
  run: |
    vault kv get -field=password secret/data/db


Use fetched secrets temporarily (e.g., for build or deployment).

Revoke the token after use:

vault token revoke -self


✅ Security Tip: Never hardcode RoleID/SecretID — use GitHub encrypted secrets.

💡 5. How do you handle secret rotation for static secrets (like API keys)?

Answer:

Use Vault KV v2 engine to version secrets.

Implement a rotation script or function:

Generate a new key.

Write it to Vault (vault kv put secret/api key=newkey).

Update dependent services.

Optionally, delete old versions.

Automate via Vault’s lifecycle hooks or CI/CD.

🧰 6. Scenario: Vault goes into a “Sealed” state after restart — how do you restore it automatically?

Answer:

Configure Auto-Unseal:

seal "azurekeyvault" {
  tenant_id      = "<tenant-id>"
  client_id      = "<client-id>"
  client_secret  = "<client-secret>"
  vault_name     = "my-azure-keyvault"
  key_name       = "vault-key"
}


When Vault restarts, it contacts Azure Key Vault, retrieves the encrypted master key, and unseals automatically.

✅ Eliminates manual unseal process and supports HA.

🧱 7. Scenario: How do you migrate secrets from Azure Key Vault to HashiCorp Vault?

Answer:

Export Azure secrets using:

az keyvault secret list --vault-name MyKeyVault


For each secret, use a script to write to Vault:

vault kv put secret/data/<name> value=<secret-value>


Validate access policies and TTLs.

Re-point apps to Vault’s API or sidecar instead of Azure Key Vault.

✅ Optionally, maintain dual sync temporarily during migration.

🔍 8. How do you audit and trace secret access in Vault?

Answer:

Enable audit device:

vault audit enable file file_path=/var/log/vault_audit.log


Logs include:

Timestamp

Token ID (masked)

Request path

Operation type (read/write)

You can stream logs to Azure Log Analytics or SIEM (like Splunk).

Use them to detect unauthorized access or pattern anomalies.

☁️ 9. Scenario: Design a multi-region Vault setup for DR and performance.

Answer:
Architecture:

Region A (Primary):

Active Vault cluster (Raft backend)

Writes data and serves traffic.

Region B (Secondary):

DR replication (passive) for failover.

Optional performance replica for local reads.

Replication:

vault write -f sys/replication/performance/primary/enable
vault write sys/replication/performance/secondary/enable token=<token>


Failover Strategy:

Use Terraform or Azure Automation to promote DR region.

Replicate snapshots to Azure Blob periodically.

🧩 10. Scenario: Your team detects a leaked Vault token — what steps do you take?

Answer:

Immediately revoke the token:

vault token revoke <token>


Revoke all child tokens:

vault token revoke -force <accessor>


Review audit logs for activity by that token.

Rotate the root key if the token had broad privileges.

Notify affected systems and reissue secrets if compromised.

⚡ 11. Scenario: You want Vault metrics visible in Azure Monitor. How do you set it up?

Answer:

Enable metrics endpoint:

vault monitor -telemetry-prometheus-address="0.0.0.0:9100"


Deploy Prometheus sidecar in AKS to scrape /v1/sys/metrics.

Export Prometheus metrics to Azure Monitor via Azure Managed Prometheus.

Build dashboards in Grafana or Azure Dashboard for:

Seal status

Token usage

Request latency

Storage health

🧮 12. Scenario: How do you secure Vault data-in-transit and data-at-rest?

Answer:

Data-at-rest: Encrypted by Vault’s Barrier Encryption Key (AES-256-GCM).

Data-in-transit:

Always enable TLS/HTTPS on Vault API.

Use cert-manager or Azure Key Vault-issued certs.

Optionally enforce mTLS for internal services.

🔐 13. Scenario: How do you implement least-privilege access for teams?

Answer:

Create namespaces (e.g., finance/, devops/, hr/).

Define fine-grained ACL policies:

path "secret/data/finance/*" {
  capabilities = ["read", "list"]
}


Bind users/groups via Azure AD or AppRole with these policies.

Use Vault namespaces (Enterprise) for multi-tenancy.

🧩 14. Scenario: Your app needs to encrypt user SSNs before storing them in DB using Vault.

Answer:
Use Transit Secrets Engine:

Enable:

vault secrets enable transit


Create key:

vault write -f transit/keys/ssn-key


App encrypts:

vault write transit/encrypt/ssn-key plaintext=$(base64 <<< "123-45-6789")


App decrypts when needed:

vault write transit/decrypt/ssn-key ciphertext=<vault:...>


Vault never stores plaintext — only the ciphertext.

🧠 15. Scenario: Vault performance is slow; what do you check?

Answer:

Check backend latency (vault operator raft list-peers)

Monitor network latency (especially if using remote storage like Azure Blob)

Verify that audit logging isn’t overwhelming I/O

Review CPU/memory usage

Ensure you’re not overusing dynamic leases (excessive renewal load)

Scale out with Performance Replication or HA Standby nodes

⚙️ 16. Scenario: You want to restrict Vault access to internal network only.

Answer:

Deploy Vault in private subnet/VNet.

Use Azure Private Endpoint.

Access only via bastion host or VPN.

Apply network security groups (NSGs) to restrict ports:

Allow 8200 (Vault API) only from internal IPs.

🧩 17. Scenario: How would you monitor and alert on Vault token expiration?

Answer:

Periodically query /sys/leases/lookup via script or Prometheus exporter.

Set alert if TTL < threshold (e.g., 6 hours).

Auto-renew tokens with vault token renew or a cron job.

Send alerts to Azure Monitor or Slack via webhook.

🔄 18. Scenario: You need to rotate the unseal keys safely. How do you do it?

Answer:
Run:

vault operator rotate


Then re-distribute new unseal keys securely to key holders.
Rotation re-encrypts the master key with new shares — no downtime required.
✅ Always backup before rotation.

📜 19. Scenario: What happens when Vault lease expires and app still uses old credentials?

Answer:

Vault revokes the credential (e.g., deletes DB user).

The app’s access fails.

Mitigation:

Renew the lease automatically using Vault Agent or SDK.

Use vault agent renew for long-running apps.

🚀 20. Bonus — Best Practices Summary
Area	Best Practice
Secrets TTL	Keep short, auto-rotate regularly
Auth Methods	Prefer OIDC/AppRole over tokens
Audit Logging	Always enable file or syslog audit
Storage	Use Raft with snapshots
Unseal	Automate with Azure Key Vault
TLS	Mandatory, mTLS for internal
Monitoring	Prometheus + Azure Monitor
Backup	Regular raft snapshots to Azure Blob
  ```
