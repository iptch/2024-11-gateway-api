### Configure Vault

# Enable and configure the Vault PKI secrets engine.
resource "vault_mount" "pki" {
  path                      = "pki" 
  type                      = "pki"  
  default_lease_ttl_seconds = 3600 
  max_lease_ttl_seconds     = 311040000  # Maximum lease time (~10 years).
  description               = "PKI secrets engine" 

  depends_on = [docker_container.vault, null_resource.wait_for_vault]
}

# Create a self-signed root certificate.
resource "vault_pki_secret_backend_root_cert" "root_cert" {
  backend = vault_mount.pki.path  
  type    = "internal"

  common_name = "svc Root"  
  ttl         = "87600h"  # Time-to-live for the certificate (~10 years).

  depends_on = [vault_mount.pki]
}

# Store the root CA certificate locally.
resource "local_file" "ca_cert" {
  content  = vault_pki_secret_backend_root_cert.root_cert.certificate
  filename = "${path.module}/ca_root.crt"

  depends_on = [vault_pki_secret_backend_root_cert.root_cert]
}

# Configure the URLs for the Vault PKI secrets engine.
resource "vault_pki_secret_backend_config_urls" "pki_urls" {
  backend = vault_mount.pki.path

  issuing_certificates    = ["${var.vault_address}/v1/${vault_mount.pki.path}/ca"]
  crl_distribution_points = ["${var.vault_address}/v1/${vault_mount.pki.path}/crl"]

  depends_on = [vault_pki_secret_backend_root_cert.root_cert]
}

# Enable an intermediate PKI secrets engine.
resource "vault_mount" "pki_int" {
  path                      = "pki_int"
  type                      = "pki"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 311040000
  description               = "PKI intermediate secrets engine"

  depends_on = [vault_pki_secret_backend_config_urls.pki_urls]
}

# Create a Certificate Signing Request (CSR) for the intermediate CA.
resource "vault_pki_secret_backend_intermediate_cert_request" "pki_int" {
  backend = vault_mount.pki_int.path
  type    = "internal"

  common_name = "svc Intermediate Authority" 

  depends_on = [vault_mount.pki_int]
}

# Store the CSR locally for signing.
resource "local_file" "pki_intermediate_csr" {
  content  = vault_pki_secret_backend_intermediate_cert_request.pki_int.csr
  filename = "${path.module}/pki_intermediate.csr"

  depends_on = [vault_pki_secret_backend_intermediate_cert_request.pki_int]
}

# Sign the intermediate CSR with the root CA to generate the intermediate certificate.
resource "vault_pki_secret_backend_root_sign_intermediate" "pki_int_signed" {
  backend = vault_mount.pki.path  # Root CA backend.
  csr     = vault_pki_secret_backend_intermediate_cert_request.pki_int.csr

  common_name = "svc Intermediate Authority"
  ttl         = "43800h"  # TTL for the intermediate cert (~5 years).
  format      = "pem_bundle"

  depends_on = [
    vault_pki_secret_backend_intermediate_cert_request.pki_int,
    vault_mount.pki
  ]
}

# Store the signed intermediate certificate locally.
resource "local_file" "intermediate_cert_pem" {
  content  = vault_pki_secret_backend_root_sign_intermediate.pki_int_signed.certificate
  filename = "${path.module}/pki_intermediate.cert.pem"

  depends_on = [vault_pki_secret_backend_root_sign_intermediate.pki_int_signed]
}

# Set the signed intermediate certificate in the 'pki_int' backend.
resource "vault_pki_secret_backend_intermediate_set_signed" "pki_int" {
  backend     = vault_mount.pki_int.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.pki_int_signed.certificate

  depends_on = [vault_pki_secret_backend_root_sign_intermediate.pki_int_signed]
}

# Configure the PKI URLs for 'pki_int'.
resource "vault_pki_secret_backend_config_urls" "pki_int_urls" {
  backend = vault_mount.pki_int.path

  issuing_certificates    = ["${var.vault_address}/v1/${vault_mount.pki_int.path}/ca"]
  crl_distribution_points = ["${var.vault_address}/v1/${vault_mount.pki_int.path}/crl"]

  depends_on = [vault_pki_secret_backend_intermediate_set_signed.pki_int]
}

# Enable AppRole authentication in Vault.
resource "vault_auth_backend" "approle" {
  type        = "approle"
  description = "AppRole auth backend"

  depends_on = [vault_pki_secret_backend_intermediate_set_signed.pki_int]
}

# Define a role in the intermediate PKI backend for certificate issuance.
resource "vault_pki_secret_backend_role" "cluster_dot_local" {
  backend         = vault_mount.pki_int.path
  name            = "cluster-dot-local"
  allowed_domains = ["cluster.local"]  # Domain restrictions for certs.
  allow_subdomains = true  # Allow subdomains for this role.
  max_ttl         = "72h" 

  depends_on = [vault_pki_secret_backend_config_urls.pki_int_urls]
}

# Create a policy for cert-manager to access the PKI.
resource "vault_policy" "cert_manager" {
  name = "cert-manager"

  policy = <<EOF
path "${vault_mount.pki_int.path}/sign/${vault_pki_secret_backend_role.cluster_dot_local.name}" {
  capabilities = ["update"] 
}
EOF

  depends_on = [
    vault_auth_backend.approle,
    vault_pki_secret_backend_role.cluster_dot_local
  ]
}

# Create an AppRole for cert-manager with the associated policy.
resource "vault_approle_auth_backend_role" "cert_manager" {
  backend        = vault_auth_backend.approle.path
  role_name      = "cert-manager"
  token_policies = [vault_policy.cert_manager.name]
  token_ttl      = 3600      # Token TTL (1 hour).
  token_max_ttl  = 14400     # Maximum token TTL (4 hours).

  depends_on = [vault_policy.cert_manager]
}

# Generate a secret ID for the cert-manager AppRole.
resource "vault_approle_auth_backend_role_secret_id" "cert_manager" {
  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.cert_manager.role_name

  depends_on = [vault_approle_auth_backend_role.cert_manager]
}
