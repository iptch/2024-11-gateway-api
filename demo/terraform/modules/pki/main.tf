# modules/pki/main.tf

variable "vault_address" {
  type        = string
  description = "The address of the Vault server."
}

variable "vault_root_token" {
  type        = string
  description = "The root token for Vault."
  sensitive   = true
}

# Configure the PKI secrets engine at 'pki' path
resource "vault_mount" "pki" {
  path                      = "pki"
  type                      = "pki"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 311040000
}

# Create a self-signed root certificate
resource "vault_pki_secret_backend_root_cert" "root_cert" {
  backend     = vault_mount.pki.path
  type        = "internal"
  common_name = "svc Root"
  ttl         = "87600h" # 10 years
}

# Store the root CA certificate locally
resource "local_file" "ca_cert" {
  content  = vault_pki_secret_backend_root_cert.root_cert.certificate
  filename = "${path.module}/ca_root.crt"
}

# Configure the URLs for the PKI
resource "vault_pki_secret_backend_config_urls" "pki_urls" {
  backend                 = vault_mount.pki.path
  issuing_certificates    = ["${var.vault_address}/v1/${vault_mount.pki.path}/ca"]
  crl_distribution_points = ["${var.vault_address}/v1/${vault_mount.pki.path}/crl"]
}

# Enable intermediate PKI at 'pki_int' path
resource "vault_mount" "pki_int" {
  path                      = "pki_int"
  type                      = "pki"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 311040000
}

# Generate CSR for intermediate CA
resource "vault_pki_secret_backend_intermediate_cert_request" "pki_int" {
  backend     = vault_mount.pki_int.path
  type        = "internal"
  common_name = "svc Intermediate Authority"
}

# Sign the intermediate CSR with the root CA
resource "vault_pki_secret_backend_root_sign_intermediate" "pki_int_signed" {
  backend     = vault_mount.pki.path
  csr         = vault_pki_secret_backend_intermediate_cert_request.pki_int.csr
  common_name = "svc Intermediate Authority"
  ttl         = "43800h" # 5 years
  format      = "pem_bundle"
}

# Set the signed intermediate certificate
resource "vault_pki_secret_backend_intermediate_set_signed" "pki_int" {
  backend     = vault_mount.pki_int.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.pki_int_signed.certificate
}

# Configure the URLs for the intermediate PKI
resource "vault_pki_secret_backend_config_urls" "pki_int_urls" {
  backend                 = vault_mount.pki_int.path
  issuing_certificates    = ["${var.vault_address}/v1/${vault_mount.pki_int.path}/ca"]
  crl_distribution_points = ["${var.vault_address}/v1/${vault_mount.pki_int.path}/crl"]
}

# Define a role for certificate issuance
resource "vault_pki_secret_backend_role" "cluster_local" {
  backend                     = vault_mount.pki_int.path
  name                        = "cluster-local"
  allowed_domains             = ["cluster.local", "apps.example.com"]
  allow_subdomains            = true
  allow_wildcard_certificates = true
  require_cn                  = false
  max_ttl                     = "72h"
}

output "pki_int_path" {
  value = vault_mount.pki_int.path
}

output "role_name" {
  value = vault_pki_secret_backend_role.cluster_local.name
}
