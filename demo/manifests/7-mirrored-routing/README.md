# Demo: Mirrored Routing

## Overview

This demo showcases how the Kubernetes Gateway API can mirror incoming requests to different
backends.

## Prerequisites

1. **Base Setup**: Ensure the base setup is completed before running this demo. Refer to [base setup
   instructions](../../README.md) for instructions.
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
# (add) 127.0.0.1 nginx-mirror.apps.example.com

while true; do
   curl -ksL https://nginx-mirror.apps.example.com:8443
   sleep 1s
done
```
