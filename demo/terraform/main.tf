terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

variable "vault_address" {
  default = "http://127.0.0.1:8200"
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

provider "vault" {
  address = var.vault_address
  token   = "myroot"
}

resource "docker_image" "vault" {
  name         = "hashicorp/vault:1.17.5"
  keep_locally = false
}

resource "docker_container" "vault" {
  name  = "vault"
  image = docker_image.vault.name

  ports {
    internal = 8200
    external = 8200
  }

  env = [
    "VAULT_DEV_ROOT_TOKEN_ID=myroot",
    "VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200",
    "VAULT_ADDR=http://0.0.0.0:8200"
  ]
}

resource "null_resource" "wait_for_vault" {
  depends_on = [docker_container.vault]

  provisioner "local-exec" {
    command = "while ! curl -s ${var.vault_address}/v1/sys/health >/dev/null; do echo 'Waiting for Vault...'; sleep 1; done"
  }
}

resource "vault_mount" "pki" {
  path                      = "pki"
  type                      = "pki"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 311040000
  description               = "PKI secrets engine"

  depends_on = [null_resource.wait_for_vault]
}

resource "vault_pki_secret_backend_root_cert" "root_cert" {
  backend = vault_mount.pki.path
  type    = "internal"

  common_name = "svc"
  ttl         = "87600h"

  depends_on = [vault_mount.pki]
}

resource "local_file" "ca_cert" {
  content  = vault_pki_secret_backend_root_cert.root_cert.certificate
  filename = "${path.module}/CA_cert.crt"

  depends_on = [vault_pki_secret_backend_root_cert.root_cert]
}

resource "vault_pki_secret_backend_config_urls" "pki_urls" {
  depends_on = [vault_pki_secret_backend_root_cert.root_cert]

  backend = vault_mount.pki.path

  issuing_certificates    = ["${var.vault_address}/v1/${vault_mount.pki.path}/ca"]
  crl_distribution_points = ["${var.vault_address}/v1/${vault_mount.pki.path}/crl"]
}

resource "vault_mount" "pki_int" {
  path                      = "pki_int"
  type                      = "pki"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 311040000
  description               = "PKI intermediate secrets engine"

  depends_on = [vault_pki_secret_backend_config_urls.pki_urls]
}

# Generate the intermediate CA and output the CSR
resource "vault_pki_secret_backend_intermediate_cert_request" "pki_int" {
  backend = vault_mount.pki_int.path
  type    = "internal"

  common_name = "svc Intermediate Authority"

  depends_on = [vault_mount.pki_int]
}

# Save the CSR to a file
resource "local_file" "pki_intermediate_csr" {
  content  = vault_pki_secret_backend_intermediate_cert_request.pki_int.csr
  filename = "${path.module}/pki_intermediate.csr"

  depends_on = [vault_pki_secret_backend_intermediate_cert_request.pki_int]
}

# STEP 4: Sign the intermediate CSR with the root CA
resource "vault_pki_secret_backend_root_sign_intermediate" "pki_int_signed" {
  backend = vault_mount.pki.path  # Root CA backend
  csr = vault_pki_secret_backend_intermediate_cert_request.pki_int.csr

  common_name = "svc Intermediate Authority"
  ttl         = "43800h"
  format      = "pem_bundle"

  depends_on = [
    vault_pki_secret_backend_intermediate_cert_request.pki_int,
    vault_mount.pki
  ]
}

# Save the signed intermediate certificate to a file
resource "local_file" "intermediate_cert_pem" {
  content  = vault_pki_secret_backend_root_sign_intermediate.pki_int_signed.certificate
  filename = "${path.module}/intermediate.cert.pem"

  depends_on = [vault_pki_secret_backend_root_sign_intermediate.pki_int_signed]
}

# STEP 5: Set the signed certificate in the 'pki_int' backend
resource "vault_pki_secret_backend_intermediate_set_signed" "pki_int" {
  backend     = vault_mount.pki_int.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.pki_int_signed.certificate

  depends_on = [vault_pki_secret_backend_root_sign_intermediate.pki_int_signed]
}

# Configure the PKI URLs for 'pki_int'
resource "vault_pki_secret_backend_config_urls" "pki_int_urls" {
  backend = vault_mount.pki_int.path

  issuing_certificates    = ["${var.vault_address}/v1/${vault_mount.pki_int.path}/ca"]
  crl_distribution_points = ["${var.vault_address}/v1/${vault_mount.pki_int.path}/crl"]

  depends_on = [vault_pki_secret_backend_intermediate_set_signed.pki_int]
}

# Enable the AppRole auth method
resource "vault_auth_backend" "approle" {
  type        = "approle"
  description = "AppRole auth backend"

  depends_on = [vault_pki_secret_backend_intermediate_set_signed.pki_int]
}

# Create a role named "cluster-dot-local" in the pki_int backend
resource "vault_pki_secret_backend_role" "cluster_dot_local" {
  backend         = vault_mount.pki_int.path
  name            = "cluster-dot-local"
  allowed_domains = ["cluster.local"]
  allow_subdomains = true
  max_ttl         = "72h"

  depends_on = [vault_pki_secret_backend_config_urls.pki_int_urls]
}

# Create the cert-manager policy
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

# Create the AppRole named cert-manager
resource "vault_approle_auth_backend_role" "cert_manager" {
  backend       = vault_auth_backend.approle.path
  role_name     = "cert-manager"
  token_policies = [vault_policy.cert_manager.name]
  token_ttl     = 3600      # 1h in seconds
  token_max_ttl = 14400     # 4h in seconds

  depends_on = [vault_policy.cert_manager]
}

# Generate a secret-id for the AppRole
resource "vault_approle_auth_backend_role_secret_id" "cert_manager" {
  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.cert_manager.role_name

  depends_on = [vault_approle_auth_backend_role.cert_manager]
}
