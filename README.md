# 2024-11-gateway-api

Repository containing the demo environment and presentation for Kubernetes Gateway API.

## Setup

TODO add information about the setups.

## Idea

### Presentation

Content:

- what are ingresses, providers (nginx, traefik)
- what are routes
- what are service meshes, providers (istio, cilium)
- what is the gateway api, providers (https://gateway-api.sigs.k8s.io/implementations/)
- how is it different from ingress/route?

### Demo

Demo:

1. Explain the setup, including existing Gateway and HTTPRoutes.
2. Create new Gateways for ingress using a different port (81-100).
3. Create an HTTPRoute to showcase north-south traffic.
4. Potentially showcase TCPRoute to show routing for TCP workloads.
5. Create a Gateway for an istio Waypoint (showcase east/west traffic).
6. Use routes and gateways to enforce authentication or similar.
