# 2024-11-gateway-api

Repository containing the demo environment and presentation for Kubernetes Gateway API

## Idea

### Presentation

Content:

- what are ingresses, providers (nginx, traefik)
- what are routes
- what are service meshes, providers (istio, cilium)
- what is the gateway api, providers (https://gateway-api.sigs.k8s.io/implementations/)
- how is it different from ingress/route?

### Demo

Setup:

- Use KinD for local cluster
- Deploy Vault externally (docker / dev mode to avoid unseal)
- Deploy ArgoCD
- Deploy cert-manager and istio-csr to link istio with cert manager (via argocd)
- Link cert-manager with vault for PKI (use kube auth and terraform for config)
- Deploy Istio in Ambient mode (sidecar less), via argocd

Links:

- https://www.solo.io/blog/istio-ambient-argo-cd-kind-15-minutes/
- https://medium.com/israeli-tech-radar/how-to-integrate-vault-as-external-root-ca-with-cert-manager-istio-csr-and-istio-7684baa369db

Demo:

- Showcase different apps (HTTP/TCP/etc) ingress
- Showcase east-west traffic (SM integration)
