# 2024-11-gateway-api

Repository containing the demo environment and presentation for Kubernetes Gateway API.

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
8. A centralized Gateway for ingress traffic
9. An HTTPbin application for testing the network
10. The HTTPRoutes needed to access HTTPbin and Kiali from outside the cluster
11. A PostgreSQL database to have a TCP based service in the cluster

<!-- TODO: add information about Vault and Cert-Manager -->

## Slides

You can find the slides under [`./slides/`](./slides/).

## Demo

Before starting the demo, set up the environment according to the guide in [`./demo/`](./demo/).

> [!NOTE]
> The initial setup already makes use of the Gateway API to expose Kiali and HTTPbin. For this, it
> uses a GatewayClass provided by Istio, a centralized Gateway shared across namespaces, and two
> HTTPRoutes routing traffic to the corresponding Kubernetes Services of the applications.

### Initial Investigation

<!-- TODO: add commands to check gateway resources deployed -->

### Gateway Deployment

<!-- TODO: deploy a new gateway to port 81 to expose other traffic -->

### HTTPRoutes

<!-- TODO: expose HTTPbin via new Gateway -->

### TCPRoutes

<!-- TODO: expose psql via new Gateway -->

### Routing Options

<!-- TODO: modify routes to show new capabilities -->

## Idea

<!-- TODO: remove this section once we have the demo -->

### Demo

Demo:

1. Explain the setup, including existing Gateway and HTTPRoutes.
2. Create new Gateways for ingress using a different port (81-100).
3. Create an HTTPRoute to showcase north-south traffic.
4. Potentially showcase TCPRoute to show routing for TCP workloads.
5. Create a Gateway for an istio Waypoint (showcase east/west traffic).
6. Use routes and gateways to enforce authentication or similar.
