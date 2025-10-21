## Cert-Manager
```
🧩 Basic Level Questions
1. What is cert-manager in Kubernetes?

Answer:
cert-manager is a Kubernetes add-on that automates the management and issuance of TLS certificates from various certificate authorities (CAs). It ensures certificates are valid and renewed before expiry.

2. Why do we use cert-manager?

Answer:
It automates the entire certificate lifecycle — issuance, renewal, and deployment — reducing manual effort and risk of downtime due to expired certificates.

3. Which certificate authorities does cert-manager support?

Answer:

Let’s Encrypt

HashiCorp Vault

Venafi

Self-signed (CA issuer)

External issuers (via custom webhook)

4. What are the key CRDs (Custom Resource Definitions) in cert-manager?

Answer:

Issuer — defines how to obtain certificates (namespace-scoped)

ClusterIssuer — same as Issuer but cluster-scoped

Certificate — requests a certificate from an issuer

CertificateRequest — internal resource created automatically

Order & Challenge — used for ACME (Let's Encrypt) flow

5. Difference between Issuer and ClusterIssuer?

Answer:

Issuer: Namespace-specific, used only in that namespace.

ClusterIssuer: Cluster-wide, usable across all namespaces.

6. How does cert-manager request a certificate?

Answer:

A Certificate resource is created.

cert-manager checks the referenced Issuer/ClusterIssuer.

A CertificateRequest and possibly Order & Challenge (for ACME) are created.

The certificate is issued and stored in a Kubernetes Secret.

⚙️ Intermediate Level Questions
7. What is ACME in cert-manager?

Answer:
ACME (Automatic Certificate Management Environment) is a protocol used by Let’s Encrypt to automate certificate issuance and validation via HTTP-01, DNS-01, or TLS-ALPN-01 challenges.

8. Explain HTTP-01 and DNS-01 challenges.

Answer:

HTTP-01: cert-manager creates a temporary pod/service to respond to ACME’s HTTP validation request.

DNS-01: cert-manager creates a DNS TXT record with a specific token for domain verification.

9. Where are issued certificates stored?

Answer:
In a Kubernetes Secret object, typically with fields:

data:
  tls.crt: <base64 certificate>
  tls.key: <base64 private key>

10. How does cert-manager renew certificates automatically?

Answer:
cert-manager continuously monitors expiration dates and renews certificates when they are close to expiry (default: when less than 2/3 of lifetime remains).

11. How can you integrate cert-manager with Ingress resources?

Answer:
Add annotations to the Ingress object:

annotations:
  cert-manager.io/cluster-issuer: "letsencrypt-prod"


cert-manager automatically creates and attaches certificates to the Ingress TLS section.

12. How do you verify cert-manager is working correctly?

Answer:

Check pods: kubectl get pods -n cert-manager

Describe certificate: kubectl describe certificate <name>

Check logs: kubectl logs deploy/cert-manager -n cert-manager

🚀 Advanced Level Questions
13. How can cert-manager work with HashiCorp Vault?

Answer:
You can configure a Vault issuer:

apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: vault-issuer
spec:
  vault:
    server: https://vault.example.com:8200
    path: pki/sign/my-role
    auth:
      tokenSecretRef:
        name: vault-token
        key: token


This allows cert-manager to request certificates directly from Vault’s PKI engine.

14. What is a CertificateRequest and when is it created?

Answer:
A CertificateRequest is automatically created when a Certificate resource needs a new certificate or renewal. It holds the CSR (Certificate Signing Request) data.

15. How do you troubleshoot a certificate not being issued?

Answer:

Check events:
kubectl describe certificate <name>

Check the CertificateRequest status:
kubectl get certificaterequest -A

Inspect cert-manager logs:
kubectl logs deploy/cert-manager -n cert-manager

16. Can cert-manager issue wildcard certificates?

Answer:
Yes, but only with DNS-01 challenge type, as HTTP-01 cannot validate wildcards.

17. How does cert-manager handle revocation?

Answer:
cert-manager doesn’t handle revocation directly; you must revoke certificates manually via your CA (e.g., Let’s Encrypt or Vault).

18. How to secure cert-manager itself?

Answer:

Run with least privilege RBAC.

Use service accounts and namespace isolation.

Secure webhook with mTLS.

Restrict who can create Issuer/ClusterIssuer resources.

19. What is the role of cert-manager-webhook?

Answer:
It validates and mutates cert-manager CRDs (like Certificate, Issuer) before they’re persisted to etcd — ensuring they follow proper schema and defaults.

20. How would you scale cert-manager for a large Kubernetes cluster?

Answer:

Use HorizontalPodAutoscaler for high load.

Separate Issuers for different namespaces.

Use external DNS solvers (CloudDNS, Route53, etc.) for performance.

Enable metrics and monitor with Prometheus.

🧠 Scenario-Based Questions
21. Your TLS certificates are not renewing automatically. What do you check?

Answer:

Expiration date of certificates.

cert-manager logs for renewal errors.

Issuer/ClusterIssuer validity.

Webhook availability.

Secret permissions.

22. You want to issue certificates for internal services (not public DNS). How would you do it?

Answer:
Use a self-signed Issuer or Vault PKI Issuer, not Let’s Encrypt (which requires public validation).

23. How to migrate cert-manager configuration between clusters?

Answer:
Export Issuers/ClusterIssuers and Certificates YAMLs, reapply them to the new cluster, and ensure secrets (like tokens) are also recreated.

24. How to monitor cert-manager certificates in Prometheus/Grafana?

Answer:
cert-manager exposes Prometheus metrics such as:

certmanager_certificate_expiration_timestamp_seconds

certmanager_certificate_ready_status
These can be visualized in Grafana dashboards.

25. Can cert-manager issue certificates for non-Kubernetes workloads?

Answer:
Not directly — cert-manager is Kubernetes-native. However, you can issue certificates via its API and export the secrets for external use.
```
