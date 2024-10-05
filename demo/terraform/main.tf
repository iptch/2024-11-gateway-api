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
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_image" "vault" {
  name         = "vault:1.13.3"
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

# Wait for Vault server to be ready
resource "null_resource" "wait_for_vault" {
  depends_on = [docker_container.vault]

  provisioner "local-exec" {
    command = "while ! curl -s http://0.0.0.0:8200/v1/sys/health >/dev/null; do echo 'Waiting for Vault...'; sleep 1; done"
  }
}

# Add the Vault provider
provider "vault" {
  address = "http://0.0.0.0:8200"
  token   = "myroot"
}

resource "vault_mount" "pki" {
  path                      = "pki"
  type                      = "pki"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 86400
  description               = "PKI secrets engine"

  depends_on = [null_resource.wait_for_vault]
}
