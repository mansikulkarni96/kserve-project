#!/bin/bash

# Cleanup Script for KServe
set -e

echo "🧹 Starting KServe cleanup..."

# Delete all inference services
echo "🗑️  Deleting all InferenceServices..."
kubectl delete inferenceservice --all --all-namespaces --ignore-not-found=true

# Delete KServe
echo "❌ Uninstalling KServe..."
kubectl delete -f https://github.com/kserve/kserve/releases/download/v0.12.1/kserve.yaml --ignore-not-found=true

# Delete Knative Serving
echo "❌ Uninstalling Knative Serving..."
kubectl delete -f https://github.com/knative/net-kourier/releases/download/knative-v1.12.0/kourier.yaml --ignore-not-found=true
kubectl delete -f https://github.com/knative/serving/releases/download/knative-v1.12.0/serving-core.yaml --ignore-not-found=true
kubectl delete -f https://github.com/knative/serving/releases/download/knative-v1.12.0/serving-crds.yaml --ignore-not-found=true

# Clean up namespaces
echo "🧽 Cleaning up namespaces..."
kubectl delete namespace kserve --ignore-not-found=true
kubectl delete namespace knative-serving --ignore-not-found=true
kubectl delete namespace kourier-system --ignore-not-found=true

echo "✅ Cleanup completed!"

