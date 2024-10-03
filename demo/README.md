# Demo

We use `devbox` to install the required tooling for the setup, such as:

- `vault`
- `kind`
- `kubectl`
- `istioctl`
- `helm`

You an initialise these tools by running `devbox shell`. This might take a while initially, but
subsequent runs should be very fast.

## Setup

```bash
# create a cluster
kind create cluster
# create argocd namespace
kubectl create namespace argocd
# install argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.9.5/manifests/install.yaml
# update admin password to admin / admin
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {
    "admin.password": "$2a$10$MKSI/gQPcNHq472w1z5E1eJa89zI6WtgFu7V8..C9/P7bx3dNX642",
    "admin.passwordMtime": "'$(date +%FT%T%Z)'"
  }}'
# install gateway API CRDs
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.0.0" | kubectl apply -f -; }
# bootstrap app of apps
kubectl apply -f- <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  project: default
  source:
    path: demo/argo
    repoURL: https://github.com/iptch/2024-11-gateway-api.git
    targetRevision: main
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```
