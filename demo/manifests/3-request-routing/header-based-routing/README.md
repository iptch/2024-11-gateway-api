# Demo: Header Based Routing

## Overview
This demo showcases how the Kubernetes Gateway API can route based on the header of the request

## Prerequisites
1. **Base Setup**: Ensure the base setup is completed before running this demo. Refer to [base setup instructions](../../../README.md) for instructions.

## Getting Started

### Step 1: Run Demo
```sh
kubectl apply -f nginx-httproute.yaml

curl -k -H "conversation-time: hello" https://nginx-header.apps.example.com:8443
curl -k -H "conversation-time: bye" https://nginx-header.apps.example.com:8443
curl -k https://nginx-header.apps.example.com:8443
```