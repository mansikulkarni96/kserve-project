#!/bin/bash

# Model Testing Script
set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <model-name> [input-file]"
    echo "Example: $0 sklearn-iris examples/iris-input.json"
    exit 1
fi

MODEL_NAME=$1
INPUT_FILE=${2:-"examples/iris-input.json"}

echo "🧪 Testing model: $MODEL_NAME"

# Check if model exists
if ! kubectl get inferenceservice $MODEL_NAME &> /dev/null; then
    echo "❌ Model $MODEL_NAME not found"
    echo "Available models:"
    kubectl get inferenceservice
    exit 1
fi

# Wait for model to be ready
echo "⏳ Waiting for model to be ready..."
kubectl wait --for=condition=ready inferenceservice $MODEL_NAME --timeout=300s

# Get model status
echo "📊 Model status:"
kubectl get inferenceservice $MODEL_NAME

# Get the service URL  
SERVICE_HOSTNAME=$(kubectl get inferenceservice $MODEL_NAME -o jsonpath='{.status.url}' | cut -d/ -f3)
echo "🌐 Service hostname: $SERVICE_HOSTNAME"

# For local testing, we need to port-forward
echo "🔀 Setting up port forwarding..."
kubectl port-forward -n kourier-system service/kourier 8080:80 &
PORT_FORWARD_PID=$!

# Wait a moment for port forwarding to establish
sleep 5

# Test the model
echo "🚀 Testing inference..."
if [ -f "$INPUT_FILE" ]; then
    echo "📤 Sending request with input from $INPUT_FILE"
    curl -v -H "Host: ${SERVICE_HOSTNAME}" -H "Content-Type: application/json" \
        http://localhost:8080/v1/models/$MODEL_NAME:predict \
        -d @$INPUT_FILE
else
    echo "⚠️  Input file $INPUT_FILE not found, sending basic request"
    curl -v -H "Host: ${SERVICE_HOSTNAME}" \
        http://localhost:8080/v1/models/$MODEL_NAME
fi

# Clean up port forwarding
kill $PORT_FORWARD_PID 2>/dev/null || true

echo "🎉 Model test completed!"

