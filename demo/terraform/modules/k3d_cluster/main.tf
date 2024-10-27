# modules/k3d_cluster/main.tf

terraform {
  required_providers {
    k3d = {
      source = "sneakybugs/k3d"
      version = "1.0.1"
    }
  }
}

variable "cluster_name" {
  type        = string
  description = "Name of the k3d cluster."
}

variable "cluster_port" {
  type        = string
  description = "The port of the k3d cluster"
}

resource "k3d_cluster" "this" {
  name = var.cluster_name
  k3d_config = <<EOF
apiVersion: k3d.io/v1alpha4
kind: Simple

servers: 1
agents: 2
kubeAPI:
  hostIP: "0.0.0.0"
  hostPort: "${var.cluster_port}"
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
      - arg: "--tls-san=host.docker.internal"
        nodeFilters:
          - server:*
EOF
}

# Output the network name for other modules to use
output "network_name" {
  value = "k3d-${k3d_cluster.this.name}"
}

output "name" {
  value = k3d_cluster.this.name
}

output "cluster_ca_certificate" {
  value = k3d_cluster.this.cluster_ca_certificate
}
