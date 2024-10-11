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
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"  
}

provider "vault" {
  address = var.vault_address
  token   = "myroot"
}

# k3d module
module "k3d_cluster" {
  source = "./k3d"
}

# Vault module
module "vault" {
  source       = "./vault"
  vault_address = var.vault_address

  k3d_dependency = module.k3d_cluster
}

output "vault_address" {
  value = var.vault_address
}
