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

### Generate a GitHub PAT

See the documentation: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens

For fined-grained control, grant the token Admin and content read/write permissions on the
repository.

### Setup the Cluster

```bash
# create a cluster
kind create cluster
# install gateway API CRDs
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.0.0" | kubectl apply -f -; }
# bootstrap flux
export GITHUB_TOKEN='<redacted>'
flux bootstrap github \
  --token-auth \
  --owner=iptch \
  --repository=2024-11-gateway-api \
  --branch=main \
  --path=demo/flux/ \
  --private=false
```
