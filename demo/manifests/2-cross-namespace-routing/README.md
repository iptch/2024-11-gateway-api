# Demo: Cross Namespace Routing

## Overview
This demo showcases how the Kubernetes Gateway API can limit the namespaces to which the Gateway can route requests

## Prerequisites
1. **Base Setup**: Ensure the base setup is completed before running this demo. Refer to [base setup instructions](../../README.md) for instructions.

## Getting Started

### Step 1: Run Demo
```sh
kubectl apply -k .

curl -k https://allowed.apps.example.com:8443
curl -kv https://prohibited.apps.example.com:8443
```
