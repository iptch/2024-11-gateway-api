# Demo: L4 Routing

## Overview

This demo showcases how the Kubernetes Gateway API can route TCP requests (Layer 4)

## Prerequisites

1. **Base Setup**: Ensure the base setup is completed before running this demo. Refer to [base setup
   instructions](../../README.md) for instructions.

## Getting Started

### Step 1: Run Demo

```sh
kubectl apply -f postgres-tcproute.yaml

# when prompted for password, enter "demo"
psql -h localhost -p 5432 demo demo
```
