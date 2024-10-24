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
    k3d = {
      source  = "sneakybugs/k3d"
      version = "1.0.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.0"
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

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "k3d-gateway-demo"
}

resource "k3d_cluster" "mycluster" {
  name = "gateway-demo"
  k3d_config = <<EOF
apiVersion: k3d.io/v1alpha4
kind: Simple

servers: 1
agents: 2
image: rancher/k3s:v1.31.1-k3s1
ports:
  - port: 8080-8100:80-100
    nodeFilters:
      - loadbalancer
options:
  k3s:
    extraArgs:
      - arg: "--disable=traefik"
        nodeFilters:
          - server:*
EOF
}

# Wait for Kubernetes API to be ready
resource "null_resource" "wait_for_kubernetes" {
  depends_on = [k3d_cluster.mycluster]

  provisioner "local-exec" {
    command = "until kubectl get nodes; do echo 'Waiting for Kubernetes...'; sleep 5; done"
  }
}

# Create a Kubernetes Service Account for Vault
resource "kubernetes_service_account" "vault" {
  metadata {
    name      = "vault-auth"
    namespace = "default"
  }

  automount_service_account_token = true

  depends_on = [null_resource.wait_for_kubernetes]
}

resource "docker_image" "vault" {
  name         = "hashicorp/vault:1.17.5"
  keep_locally = true
}

resource "docker_container" "vault" {
  name  = "vault"
  image = docker_image.vault.name

  # Map the Vault internal port to the host's external port.
  ports {
    internal = 8200
    external = 8200
  }

  # Set environment variables for Vault.
  env = [
    "VAULT_DEV_ROOT_TOKEN_ID=myroot",
    "VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200",
    "VAULT_ADDR=http://0.0.0.0:8200"
  ]

  # Connect to the k3d-gateway-demo network
  networks_advanced {
    name = "k3d-gateway-demo"
  }
  depends_on = [k3d_cluster.mycluster]
}

resource "null_resource" "wait_for_vault" {
  depends_on = [docker_container.vault]

  provisioner "local-exec" {
    command = "while ! curl -s ${var.vault_address}/v1/sys/health >/dev/null; do echo 'Waiting for Vault...'; sleep 1; done"
  }
}

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

# Define a role in the intermediate PKI backend for certificate issuance.
resource "vault_pki_secret_backend_role" "cluster_dot_local" {
  backend         = vault_mount.pki_int.path
  name            = "cluster-dot-local"
  allowed_domains = ["cluster.local"]  # Domain restrictions for certs.
  allow_subdomains = true  # Allow subdomains for this role.
  max_ttl         = "72h" 

  depends_on = [vault_pki_secret_backend_config_urls.pki_int_urls]
}

# Enable the Kubernetes Auth Method
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"

  depends_on = [null_resource.wait_for_vault]
}

data "external" "vault_sa_token" {
  program = ["bash", "-c", <<-EOT
    kubectl -n default create token vault-auth --duration=8760h --audience=vault | jq -nR '{ "token": input }'
  EOT
  ]
  depends_on = [kubernetes_service_account.vault]
}

# Configure the Kubernetes Auth Backend
resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend             = vault_auth_backend.kubernetes.path
  kubernetes_host     = k3d_cluster.mycluster.host
  kubernetes_ca_cert  = base64decode(k3d_cluster.mycluster.cluster_ca_certificate)
  token_reviewer_jwt  = data.external.vault_sa_token.result["token"]


  depends_on = [
    vault_auth_backend.kubernetes,
    data.external.vault_sa_token,
    null_resource.wait_for_kubernetes
  ]
}

# Create a Policy for cert-manager
resource "vault_policy" "cert_manager" {
  name = "cert-manager"

  policy = <<EOF
path "${vault_mount.pki_int.path}/sign/${vault_pki_secret_backend_role.cluster_dot_local.name}" {
  capabilities = ["update"]
}
EOF

  depends_on = [
    vault_auth_backend.kubernetes
  ]
}

# Create a Role for cert-manager
resource "vault_kubernetes_auth_backend_role" "cert_manager" {
  backend                       = vault_auth_backend.kubernetes.path
  role_name                     = "cert-manager"
  bound_service_account_names   = ["cert-manager"]
  bound_service_account_namespaces = ["cert-manager"]
  token_policies                = ["cert-manager"]
  token_ttl                           = 3600

  depends_on = [vault_kubernetes_auth_backend_config.kubernetes]
}
