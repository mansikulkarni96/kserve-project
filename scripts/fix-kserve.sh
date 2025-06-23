#!/bin/bash

# Fix KServe deployment issues
set -e

echo "🔧 Fixing KServe deployment issues..."

# First, let's delete the current failing KServe installation
echo "🗑️ Removing current KServe installation..."
kubectl delete -f https://github.com/kserve/kserve/releases/download/v0.12.1/kserve.yaml --ignore-not-found=true

# Wait for cleanup
echo "⏳ Waiting for cleanup..."
sleep 30

# Install KServe with serverless configuration (without Istio)
echo "🤖 Installing KServe in serverless mode..."
cat << 'YAML' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: inferenceservice-config
  namespace: kserve
data:
  deploy: |
    {
      "defaultDeploymentMode": "Serverless",
      "defaultServiceAccount": "default"
    }
---
YAML

# Apply KServe installation again
kubectl apply -f https://github.com/kserve/kserve/releases/download/v0.12.1/kserve.yaml

# Patch the KServe controller deployment to increase resource limits and fix file limits
echo "⚙️ Patching KServe controller with better resource limits..."
kubectl patch deployment kserve-controller-manager -n kserve --patch '
{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "manager",
            "resources": {
              "limits": {
                "cpu": "500m",
                "memory": "1Gi"
              },
              "requests": {
                "cpu": "200m",
                "memory": "500Mi"
              }
            },
            "env": [
              {
                "name": "POD_NAMESPACE",
                "valueFrom": {
                  "fieldRef": {
                    "fieldPath": "metadata.namespace"
                  }
                }
              },
              {
                "name": "SECRET_NAME",
                "value": "kserve-webhook-server-cert"
              }
            ]
          }
        ]
      }
    }
  }
}'

echo "⏳ Waiting for KServe controller to be ready..."
kubectl rollout status deployment/kserve-controller-manager -n kserve --timeout=300s

echo "✅ KServe fix completed!"
echo "📊 Checking status..."
kubectl get pods -n kserve

