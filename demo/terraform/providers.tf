# providers.tf

terraform {
  required_version = ">= 1.0.0"

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
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "~> 1.4"
    }
  }
}

# Provider configurations
provider "docker" {
  host = "unix:///var/run/docker.sock"
}

provider "vault" {
  address = var.vault_address
  token   = var.vault_root_token
}

provider "kubernetes" {
  config_path    = var.kube_config_path
  config_context = "k3d-${var.cluster_name}"
}

provider "flux" {
  kubernetes = {
    config_path    = var.kube_config_path
    config_context = "k3d-${var.cluster_name}"
  }

  git = {
    url    = var.git_repo_url
    branch = var.git_branch
    http = {
      username = var.git_username
      password = var.github_token
    }
  }
}
