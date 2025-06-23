# KServe Model Deployment Guide

This guide will help you deploy machine learning models using KServe on Kubernetes.

## Prerequisites

1. **Kubernetes Cluster**: Access to a Kubernetes cluster (v1.25+)
2. **kubectl**: Configured to connect to your cluster
3. **Istio**: For traffic management (optional but recommended)  
4. **Knative Serving**: For serverless workloads

## Quick Start

### 1. Connect to Your Kubernetes Cluster

First, make sure you're connected to a Kubernetes cluster. You can use:
- Local cluster: minikube, kind, or k3s
- Cloud clusters: EKS, GKE, AKS
- Development: Docker Desktop with Kubernetes

```bash
# Check cluster connection
kubectl cluster-info

# If you need a local cluster, you can use kind:
kind create cluster --name kserve-demo
```

### 2. Install Prerequisites

```bash
# Install Knative Serving
kubectl apply -f setup/install-knative.yaml

# Install KServe
kubectl apply -f setup/install-kserve.yaml
```

### 3. Deploy Your First Model

```bash
# Deploy a simple scikit-learn model
kubectl apply -f examples/sklearn-iris.yaml

# Check deployment status
kubectl get inferenceservice sklearn-iris
```

### 4. Test the Model

```bash
# Run the test script
./scripts/test-model.sh sklearn-iris
```

## Model Types Supported

- **Scikit-learn**: `.pkl` files
- **TensorFlow**: SavedModel format
- **PyTorch**: TorchScript or Python pickle
- **XGBoost**: `.json` or `.ubj` files
- **ONNX**: `.onnx` files
- **Custom**: Using custom runtime

## Storage Options

- **S3**: Amazon S3 buckets
- **GCS**: Google Cloud Storage
- **Azure Blob**: Azure storage
- **HTTP**: Direct HTTP URLs
- **PVC**: Kubernetes Persistent Volume Claims

## Features

- **Auto-scaling**: Scale to zero when idle
- **Multi-framework**: Support for popular ML frameworks
- **Canary deployments**: A/B testing capabilities
- **GPU support**: For models requiring GPU acceleration
- **Monitoring**: Built-in metrics and logging

