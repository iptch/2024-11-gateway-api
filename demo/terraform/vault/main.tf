terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.0"
    }
  }
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

  networks_advanced {
    name = "k3d-gateway-demo"
  }

  depends_on = [var.k3d_dependency]
}

resource "null_resource" "wait_for_vault" {
  depends_on = [docker_container.vault]

  provisioner "local-exec" {
    command = "while ! curl -s ${var.vault_address}/v1/sys/health >/dev/null; do echo 'Waiting for Vault...'; sleep 1; done"
  }
}

output "vault_container_name" {
  value = docker_container.vault.name
}
