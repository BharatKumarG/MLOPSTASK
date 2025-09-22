# MLOps Minikube Deployment Guide

## Overview

This guide will help you deploy your MLOps application on Minikube for local development and testing. Minikube provides a lightweight Kubernetes cluster that runs locally on your machine.

## Prerequisites

### Required Software

1. **Docker Desktop**
   - Windows: [Download from Docker](https://www.docker.com/products/docker-desktop)
   - Linux: `sudo apt-get install docker.io` or similar
   - macOS: `brew install --cask docker`

2. **Minikube**
   - Windows: `winget install Kubernetes.minikube` or [Download manually](https://minikube.sigs.k8s.io/docs/start/)
   - Linux: `curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64`
   - macOS: `brew install minikube`

3. **kubectl**
   - Windows: `winget install Kubernetes.kubectl`
   - Linux: `snap install kubectl --classic`
   - macOS: `brew install kubectl`

### System Requirements

- **CPU**: 2+ cores
- **Memory**: 4GB+ RAM
- **Disk**: 10GB+ free space
- **Virtualization**: Enabled in BIOS

## Quick Start

### Option 1: Automated Setup (Recommended)

**Windows:**
```cmd
# Run the automated setup script
.\minikube-setup.bat
```

**Linux/macOS:**
```bash
# Make script executable and run
chmod +x minikube-setup.sh
./minikube-setup.sh
```

Choose option `1` for full automated setup.

### Option 2: Manual Setup

#### Step 1: Start Minikube
```bash
# Start Minikube with Docker driver
minikube start --driver=docker --cpus=4 --memory=4096 --disk-size=20g

# Enable required addons
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable dashboard
```

#### Step 2: Configure Docker Environment
```bash
# Configure Docker to use Minikube's Docker daemon
eval $(minikube docker-env)
```

#### Step 3: Build Docker Image
```bash
# Train the model first
python train_model.py

# Build Docker image (will be available in Minikube)
docker build -t ml-inference-service:latest .
```

#### Step 4: Deploy Application
```bash
# Deploy to Minikube
kubectl apply -f k8s/minikube-deployment.yaml

# Wait for deployment to be ready
kubectl wait --for=condition=available --timeout=300s deployment/ml-inference-service
```

#### Step 5: Access Your Application
```bash
# Get service URL
minikube service ml-inference-service --url

# Or use port forwarding
kubectl port-forward service/ml-inference-service 8080:80
```

## Application Architecture

### Kubernetes Resources

1. **Deployment** (`ml-inference-service`)
   - 2 replicas (optimized for Minikube)
   - Health checks and probes
   - Resource limits for local development

2. **Services**
   - `ml-inference-service`: NodePort (30080)
   - `ml-inference-service-clusterip`: ClusterIP (internal)

3. **Ingress** (Optional)
   - External access via domain name
   - CORS configuration for web access

### Resource Configuration

- **CPU**: 100m request, 300m limit
- **Memory**: 128Mi request, 256Mi limit
- **Image Pull Policy**: Never (uses local images)

## Access Methods

### 1. NodePort Service
```bash
# Get the URL (easiest method)
minikube service ml-inference-service --url

# Example output: http://192.168.49.2:30080
```

### 2. Port Forwarding
```bash
# Forward local port to service
kubectl port-forward service/ml-inference-service 8080:80

# Access at: http://localhost:8080
```

### 3. Minikube IP
```bash
# Get Minikube IP
minikube ip

# Access at: http://<MINIKUBE_IP>:30080
```

### 4. Ingress (Advanced)
```bash
# Apply ingress configuration
kubectl apply -f k8s/minikube-ingress.yaml

# Add to hosts file (Windows: C:\Windows\System32\drivers\etc\hosts)
echo "$(minikube ip) ml-api.local" >> /etc/hosts

# Access at: http://ml-api.local
```

## Available Endpoints

Once deployed, your ML API will be available at the URLs above with these endpoints:

- **Health Check**: `GET /health`
- **Model Information**: `GET /model/info`
- **Predictions**: `POST /predict`
- **Metrics**: `GET /metrics`
- **Root**: `GET /` (API documentation)

### Example API Calls

```bash
# Health check
curl http://<MINIKUBE_IP>:30080/health

# Get model information
curl http://<MINIKUBE_IP>:30080/model/info

# Make a prediction
curl -X POST http://<MINIKUBE_IP>:30080/predict \
  -H "Content-Type: application/json" \
  -d '{"features": [5.1, 3.5, 1.4, 0.2]}'

# Get Prometheus metrics
curl http://<MINIKUBE_IP>:30080/metrics
```

## Monitoring and Debugging

### View Application Logs
```bash
# Current logs
kubectl logs -l app=ml-inference-service

# Follow logs (live)
kubectl logs -l app=ml-inference-service -f

# Logs from specific pod
kubectl logs <pod-name>
```

### Check Resources
```bash
# View all resources
kubectl get all

# Check pod status
kubectl get pods -l app=ml-inference-service -o wide

# Describe pod for troubleshooting
kubectl describe pod <pod-name>
```

### Kubernetes Dashboard
```bash
# Open Kubernetes dashboard
minikube dashboard
```

### Resource Usage
```bash
# Check node resource usage
kubectl top nodes

# Check pod resource usage
kubectl top pods
```

## Troubleshooting

### Common Issues

#### 1. Image Pull Errors
```bash
# Make sure you're using Minikube's Docker daemon
eval $(minikube docker-env)

# Rebuild the image
docker build -t ml-inference-service:latest .

# Verify image exists
docker images | grep ml-inference-service
```

#### 2. Service Not Accessible
```bash
# Check service status
kubectl get services

# Check if pods are running
kubectl get pods -l app=ml-inference-service

# Check pod logs
kubectl logs -l app=ml-inference-service
```

#### 3. Resource Issues
```bash
# Check node resources
kubectl describe node minikube

# Scale down if needed
kubectl scale deployment ml-inference-service --replicas=1
```

#### 4. Minikube Issues
```bash
# Restart Minikube
minikube stop
minikube start

# Reset Minikube (last resort)
minikube delete
minikube start
```

### Performance Optimization

1. **Increase Minikube Resources**:
   ```bash
   minikube start --cpus=6 --memory=8192
   ```

2. **Reduce Application Replicas**:
   - Edit `k8s/minikube-deployment.yaml`
   - Set `replicas: 1` for single-pod testing

3. **Optimize Resource Limits**:
   - Adjust CPU/memory requests and limits
   - Monitor usage with `kubectl top pods`

## Cleanup

### Remove Application
```bash
# Delete application resources
kubectl delete -f k8s/minikube-deployment.yaml

# Delete ingress (if applied)
kubectl delete -f k8s/minikube-ingress.yaml
```

### Stop Minikube
```bash
# Stop Minikube
minikube stop

# Delete Minikube cluster (removes everything)
minikube delete
```

## Next Steps

1. **Production Deployment**: Use the regular `k8s/deployment.yaml` for production clusters
2. **CI/CD Integration**: Configure your CI/CD pipeline to deploy to Minikube for testing
3. **Monitoring**: Set up Prometheus and Grafana for comprehensive monitoring
4. **Scaling**: Test horizontal pod autoscaling with increased load

## Support

If you encounter issues:

1. Check the automated setup scripts (`minikube-setup.bat` or `minikube-setup.sh`)
2. Review logs using the debugging commands above
3. Verify all prerequisites are installed and configured
4. Check Minikube status with `minikube status`

Your MLOps application should now be running successfully on Minikube! 🚀