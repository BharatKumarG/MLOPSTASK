# Minikube NodePort Access Guide

## Overview

NodePort is the simplest way to access your MLOps application running on Minikube. It exposes your service on a static port (30080) on every Minikube node, making it accessible from outside the cluster.

## Current NodePort Configuration

Your application is already configured with NodePort:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ml-inference-service
spec:
  type: NodePort
  ports:
  - port: 80          # Internal cluster port
    targetPort: 5000  # Container port (your Flask app)
    nodePort: 30080   # External access port
    protocol: TCP
  selector:
    app: ml-inference-service
```

## Quick Access Methods

### Method 1: Automated Script (Recommended)

**Windows:**
```cmd
.\minikube-nodeport-access.bat
```

**Linux/macOS:**
```bash
chmod +x minikube-nodeport-access.sh
./minikube-nodeport-access.sh
```

### Method 2: Manual Access

#### Step 1: Get Minikube IP
```bash
minikube ip
# Example output: 192.168.49.2
```

#### Step 2: Access Your Application
Your ML API will be available at: `http://<MINIKUBE_IP>:30080`

For example: `http://192.168.49.2:30080`

### Method 3: Minikube Service Command
```bash
# This automatically opens the service in your browser
minikube service ml-inference-service

# Or get the URL without opening browser
minikube service ml-inference-service --url
```

## Available Endpoints

Once you have the base URL (e.g., `http://192.168.49.2:30080`), you can access:

| Endpoint | Method | Description | Example |
|----------|--------|-------------|---------|
| `/` | GET | API information | `curl http://192.168.49.2:30080/` |
| `/health` | GET | Health check | `curl http://192.168.49.2:30080/health` |
| `/model/info` | GET | Model information | `curl http://192.168.49.2:30080/model/info` |
| `/predict` | POST | Make predictions | `curl -X POST http://192.168.49.2:30080/predict -H "Content-Type: application/json" -d '{"features": [5.1, 3.5, 1.4, 0.2]}'` |
| `/metrics` | GET | Prometheus metrics | `curl http://192.168.49.2:30080/metrics` |

## Testing Your Application

### 1. Health Check
```bash
curl http://<MINIKUBE_IP>:30080/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "model_loaded": true,
  "timestamp": "2025-09-22T10:00:00Z",
  "version": "1.0.0"
}
```

### 2. Model Information
```bash
curl http://<MINIKUBE_IP>:30080/model/info
```

### 3. Make a Prediction
```bash
curl -X POST http://<MINIKUBE_IP>:30080/predict \
  -H "Content-Type: application/json" \
  -d '{"features": [5.1, 3.5, 1.4, 0.2]}'
```

**Expected Response:**
```json
{
  "prediction": {
    "class_id": 0,
    "class_name": "setosa",
    "confidence": 0.95
  },
  "probabilities": {
    "setosa": 0.95,
    "versicolor": 0.03,
    "virginica": 0.02
  },
  "input_features": [5.1, 3.5, 1.4, 0.2],
  "timestamp": "2025-09-22T10:00:00Z"
}
```

## Alternative Access Methods

### 1. Port Forwarding (ClusterIP Access)
If NodePort doesn't work, you can use port forwarding:

```bash
# Forward local port 8080 to the service
kubectl port-forward service/ml-inference-service-clusterip 8080:80

# Access at: http://localhost:8080
```

### 2. Browser Access
Open your web browser and navigate to:
- `http://<MINIKUBE_IP>:30080` - Main API page
- `http://<MINIKUBE_IP>:30080/health` - Health check

### 3. Direct Minikube Service
```bash
# Open service in default browser
minikube service ml-inference-service
```

## Troubleshooting

### Issue: Cannot Access the Service

#### Check 1: Verify Minikube is Running
```bash
minikube status
```

#### Check 2: Verify Service is Deployed
```bash
kubectl get services
```

You should see:
```
NAME                                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
ml-inference-service               NodePort    10.96.xxx.xxx   <none>        80:30080/TCP   5m
ml-inference-service-clusterip     ClusterIP   10.96.xxx.xxx   <none>        80/TCP         5m
```

#### Check 3: Verify Pods are Running
```bash
kubectl get pods -l app=ml-inference-service
```

You should see:
```
NAME                                   READY   STATUS    RESTARTS   AGE
ml-inference-service-xxxxxxxxxx-xxxxx   1/1     Running   0          5m
ml-inference-service-xxxxxxxxxx-xxxxx   1/1     Running   0          5m
```

#### Check 4: Check Pod Logs
```bash
kubectl logs -l app=ml-inference-service
```

### Issue: Service Not Responding

#### Solution 1: Check Pod Health
```bash
kubectl describe pods -l app=ml-inference-service
```

#### Solution 2: Restart Deployment
```bash
kubectl rollout restart deployment/ml-inference-service
```

#### Solution 3: Check NodePort Range
Minikube uses NodePort range 30000-32767. Port 30080 should work.

### Issue: Wrong IP Address

#### Solution: Get Current Minikube IP
```bash
# Get fresh IP
minikube ip

# Or restart Minikube
minikube stop
minikube start
```

## NodePort vs Other Service Types

| Service Type | Accessibility | Use Case | Pros | Cons |
|--------------|---------------|----------|------|------|
| **NodePort** | External | Development/Testing | Simple, Direct access | Limited port range |
| **ClusterIP** | Internal only | Service-to-service | Secure | Needs port-forwarding |
| **LoadBalancer** | External | Production | Automatic LB | Requires cloud provider |
| **Ingress** | External | Production | HTTP routing | More complex setup |

## Best Practices

### For Development
1. **Use NodePort** for quick testing and development
2. **Use consistent ports** (30080 is configured for you)
3. **Test all endpoints** using the provided scripts

### For Production
1. **Use Ingress** for HTTP routing
2. **Use LoadBalancer** for cloud deployments
3. **Add TLS/SSL** for security

## Example Client Code

### Python Client
```python
import requests
import json

# Configuration
MINIKUBE_IP = "192.168.49.2"  # Replace with your IP
BASE_URL = f"http://{MINIKUBE_IP}:30080"

# Test health
response = requests.get(f"{BASE_URL}/health")
print("Health:", response.json())

# Make prediction
prediction_data = {"features": [5.1, 3.5, 1.4, 0.2]}
response = requests.post(
    f"{BASE_URL}/predict",
    headers={"Content-Type": "application/json"},
    json=prediction_data
)
print("Prediction:", response.json())
```

### JavaScript Client
```javascript
const MINIKUBE_IP = "192.168.49.2";  // Replace with your IP
const BASE_URL = `http://${MINIKUBE_IP}:30080`;

// Test health
fetch(`${BASE_URL}/health`)
  .then(response => response.json())
  .then(data => console.log('Health:', data));

// Make prediction
const predictionData = { features: [5.1, 3.5, 1.4, 0.2] };
fetch(`${BASE_URL}/predict`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(predictionData)
})
  .then(response => response.json())
  .then(data => console.log('Prediction:', data));
```

## Summary

Your MLOps application is configured for NodePort access on port 30080. Use the provided scripts for easy access and testing, or manually access via `http://<MINIKUBE_IP>:30080`. The service provides a complete ML inference API with health checks, model information, and prediction capabilities.

## Quick Command Reference

```bash
# Get Minikube IP
minikube ip

# Get service URL
minikube service ml-inference-service --url

# Test health endpoint
curl http://$(minikube ip):30080/health

# Make a prediction
curl -X POST http://$(minikube ip):30080/predict \
  -H "Content-Type: application/json" \
  -d '{"features": [5.1, 3.5, 1.4, 0.2]}'

# Check service status
kubectl get services ml-inference-service

# View pod logs
kubectl logs -l app=ml-inference-service
```

Your ML API is now accessible via NodePort! 🚀