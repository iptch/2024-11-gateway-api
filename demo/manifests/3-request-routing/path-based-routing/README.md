# Demo: Path Based Routing

## Overview
This demo showcases how the Kubernetes Gateway API can route based on the path of the request

## Prerequisites
1. **Base Setup**: Ensure the base setup is completed before running this demo. Refer to [base setup instructions](../../../README.md) for instructions.

## Getting Started

### Step 1: Run Demo
```sh
kubectl apply -f nginx-httproute.yaml

sudo -e /etc/hosts
(add) 127.0.0.1 nginx-path.apps.example.com

curl -ksL https://nginx-path.apps.example.com:8443/hello
curl -ksL https://nginx-path.apps.example.com:8443/bye
```
