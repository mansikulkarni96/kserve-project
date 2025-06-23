#!/bin/bash

# KServe Deployment Script
set -e

echo "🚀 Starting KServe deployment..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check cluster connection
echo "🔍 Checking Kubernetes cluster connection..."
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ No Kubernetes cluster found. Please connect to a cluster first."
    echo "For local development, you can use:"
    echo "  - minikube start"
    echo "  - kind create cluster"
    echo "  - Enable Kubernetes in Docker Desktop"
    exit 1
fi

echo "✅ Connected to Kubernetes cluster"

# Install cert-manager (required by KServe)
echo "🔐 Installing cert-manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

echo "⏳ Waiting for cert-manager to be ready..."
kubectl wait --for=condition=ready pod -l app=cert-manager -n cert-manager --timeout=300s
kubectl wait --for=condition=ready pod -l app=cainjector -n cert-manager --timeout=300s
kubectl wait --for=condition=ready pod -l app=webhook -n cert-manager --timeout=300s

# Install Knative Serving
echo "📦 Installing Knative Serving..."
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.12.0/serving-crds.yaml
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.12.0/serving-core.yaml

echo "⏳ Waiting for Knative Serving to be ready..."
kubectl wait --for=condition=ready pod -l app=controller -n knative-serving --timeout=300s
kubectl wait --for=condition=ready pod -l app=activator -n knative-serving --timeout=300s

# Install Kourier networking layer for Knative
echo "🌐 Installing Kourier networking..."
kubectl apply -f https://github.com/knative/net-kourier/releases/download/knative-v1.12.0/kourier.yaml

echo "⏳ Waiting for Kourier to be ready..."
kubectl wait --for=condition=ready pod -l app=3scale-kourier-gateway -n kourier-system --timeout=300s

kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'

# Install KServe
echo "🤖 Installing KServe..."
kubectl apply -f https://github.com/kserve/kserve/releases/download/v0.12.1/kserve.yaml

echo "⏳ Waiting for KServe to be ready..."
kubectl wait --for=condition=ready pod -l control-plane=kserve-controller-manager -n kserve --timeout=300s

# Configure domain (for local development)
echo "🔧 Configuring domain for local development..."
kubectl patch configmap/config-domain \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"example.com":""}}'

echo "✅ KServe installation completed successfully!"
echo ""
echo "📊 Installation Summary:"
echo "  ✅ cert-manager: $(kubectl get pods -n cert-manager -l app=cert-manager --no-headers | wc -l) pods running"
echo "  ✅ Knative Serving: $(kubectl get pods -n knative-serving --no-headers | wc -l) pods running"
echo "  ✅ Kourier: $(kubectl get pods -n kourier-system --no-headers | wc -l) pods running"
echo "  ✅ KServe: $(kubectl get pods -n kserve --no-headers | wc -l) pods running"
echo ""
echo "📝 You can now deploy models using the examples in the examples/ directory"
echo "🧪 Run './scripts/test-model.sh sklearn-iris' after deploying a model to test it"

