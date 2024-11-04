# Demo: HTTP Header Modifier

## Overview
This demo showcases how the Kubernetes Gateway API can rework the HTTP headers from incoming requests.

## Prerequisites
1. **Base Setup**: Ensure the base setup is completed before running this demo. Refer to [base setup instructions](../../README.md) for instructions.

## Getting Started

### Step 1: Set Up Base Resources
If you haven’t already set up the base resources, run the following commands from the base directory:
```sh
kubectl apply -f httproute.yaml
curl -kL -H "gateway-demo-version: 0.0" https://httpbin-header-modifier.apps.example.com:8443/headers | jq
```