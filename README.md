# 2024-11-gateway-api

This repository contains the infrastructure setup for a demo to showcase the new Gateway API, and
how it integrates with other components to simplify aspects such as certificate management, network
visualisation, etc.

## Setup

The demo environment we are setting up here utilises `k3d` to setup a 3 node Kubernetes cluster.
Once the cluster is ready, we use FluxCD to deploy the required infrastructure and applications for
the demo environment. This is done using the manifests found under [`./demo/flux/`](./demo/flux/).
This will deploy, in the order listed here:

1. The Gateway API CRDs
2. Istio CRDs
3. The Istio CNI
4. The Istio control plane (`istiod`)
5. ztunnel for inter-node communication
6. A Prometheus instance
7. Kiali, for network visualisation
8. Cert-Manager for the management of certificates
9. A centralized Gateway for ingress traffic
10. An HTTPbin application for testing the network
11. The HTTPRoutes needed to access HTTPbin and Kiali from outside the cluster
12. A PostgreSQL database to have a TCP based service in the cluster

In order to have Cert-Manager be able to issue certificates, we also configure a HashiCorp Vault
instance outside of `k3d` cluster to act as a PKI.

## Demo

Before starting the demo, set up the environment according to the guide in [`./demo/`](./demo/).

> [!NOTE]
> The initial setup already makes use of the Gateway API to expose Kiali and HTTPbin. For this, it
> uses a GatewayClass provided by Istio, a centralized Gateway shared across namespaces, and two
> HTTPRoutes routing traffic to the corresponding Kubernetes Services of the applications.
