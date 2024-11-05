# Demo: URL Rewrite

## Overview
This demo showcases how the Kubernetes Gateway API can rewrite the requests URL

## Prerequisites
1. **Base Setup**: Ensure the base setup is completed before running this demo. Refer to [base setup instructions](../../../README.md) for instructions.

## Getting Started

### Step 1: Run Demo
```sh
kubectl apply -f httproute-rewrite.yaml

curl -k https://httpbin.apps.example.com:8443/urlrewrite | jq
```
