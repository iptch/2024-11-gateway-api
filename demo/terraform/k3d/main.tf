terraform {
  required_providers {
    k3d = {
      source  = "sneakybugs/k3d"
      version = "1.0.1"
    }
  }
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

output "k3d_cluster_name" {
  value = k3d_cluster.mycluster.name
}
