# Demo: Wieghted Traffic Splitting

## Overview

This demo showcases how the Kubernetes Gateway API can redirect requests to different backends based
on a weight.

## Prerequisites

1. **Base Setup**: Ensure the base setup is completed before running this demo. Refer to [base setup
   instructions](../../../README.md) for instructions.
2. **Deploy Hello/Bye**: Ensure that the resources form [request
   routing](../3-request-routing/kustomization.yaml) is deployed. Otherwise deploy it:
   ```bash
   kubectl apply -k ../manifests/3-request-routing/
   ```

## Getting Started

### Step 1: Run Demo

```bash
kubectl apply -f httproute.yaml

sudo -e /etc/hosts
# (add) 127.0.0.1 nginx-weighted.apps.example.com

while true; do
   curl -ksL https://nginx-weighted.apps.example.com:8443
   sleep 1s
done
```

This demo is nice to see in Kiali.
