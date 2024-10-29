# modules/vault/main.tf

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.0" # adjust based on your version requirements
    }
    # add other providers as necessary
  }
}

variable "vault_address" {
  type        = string
  description = "The address of the Vault server."
}

variable "vault_root_token" {
  type        = string
  description = "The root token for Vault."
  sensitive   = true
}

variable "docker_network" {
  type        = string
  description = "Docker network to connect Vault container."
}

resource "docker_image" "vault" {
  name         = "hashicorp/vault:1.17.5"
  keep_locally = true
}

resource "docker_container" "vault" {
  name  = "vault"
  image = docker_image.vault.image_id

  ports {
    internal = 8200
    external = 8200
  }

  env = [
    "VAULT_DEV_ROOT_TOKEN_ID=${var.vault_root_token}",
    "VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200",
    "VAULT_ADDR=${var.vault_address}",
    "VAULT_LOG_LEVEL=trace"
  ]

  network_mode = "bridge"

  networks_advanced {
    name = var.docker_network
  }
}

# Wait for Vault to become healthy using the 'http' data source
data "http" "vault_health" {
  url = "${var.vault_address}/v1/sys/health"

  request_headers = {
    "Content-Type" = "application/json"
  }

  retry {
    attempts     = 30
    max_delay_ms = 2000
    min_delay_ms = 1000
  }

  request_timeout_ms = 2000

  depends_on = [docker_container.vault]
}
