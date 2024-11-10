# Demo: URL Redirect

## Overview

This demo showcases how the Kubernetes Gateway API can redirect requests.

## Prerequisites

1. **Base Setup**: Ensure the base setup is completed before running this demo. Refer to [base setup
   instructions](../../../README.md) for instructions.

## Getting Started

### Step 1: Run Demo

```bash
kubectl apply -f httproute-redirect.yaml

sudo -e /etc/hosts
# (add) 127.0.0.1 httpbin.apps.example.com

curl -kL https://httpbin.apps.example.com:8443/redirect | jq
```
