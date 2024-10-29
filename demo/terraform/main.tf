# main.tf

# Create k3d cluster using module
module "k3d_cluster" {
  source       = "./modules/k3d_cluster"
  cluster_name = var.cluster_name
  cluster_port = var.cluster_port
}

# Deploy Vault using module
module "vault" {
  source = "./modules/vault"

  vault_address    = var.vault_address
  vault_root_token = var.vault_root_token
  docker_network   = module.k3d_cluster.network_name

  depends_on = [module.k3d_cluster]
}

# Set up PKI using module
module "pki" {
  source = "./modules/pki"

  vault_address    = var.vault_address
  vault_root_token = var.vault_root_token

  depends_on = [module.vault]
}

resource "flux_bootstrap_git" "this" {
  embedded_manifests = true
  path               = "demo/flux/"

  depends_on = [module.k3d_cluster]
}

# Set up cert-manager configurations
module "cert_manager" {
  source = "./modules/cert_manager"

  kubernetes_host        = "https://k3d-${var.cluster_name}-server-0:6443"
  pki_int_path           = module.pki.pki_int_path
  role_name              = module.pki.role_name
  cluster_ca_certificate = module.k3d_cluster.cluster_ca_certificate

  depends_on = [
    module.k3d_cluster,
    module.vault,
    module.pki,
    flux_bootstrap_git.this
  ]
}
