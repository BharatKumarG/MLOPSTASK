# MLOps Task Execution Guide

This comprehensive guide provides step-by-step instructions to set up, run, and deploy the ML inference service project created by **Bharath Kumar**.

## 📋 Table of Contents

1. [Prerequisites](#-prerequisites)
2. [Environment Setup](#-environment-setup)
3. [Local Development](#-local-development)
4. [Testing](#-testing)
5. [Docker Deployment](#-docker-deployment)
6. [Kubernetes Deployment](#-kubernetes-deployment)
7. [Monitoring](#-monitoring)
8. [Troubleshooting](#-troubleshooting)

## 🛠 Prerequisites

### Required Software
- **Python**: 3.9+ (3.12 recommended)
- **Docker**: Latest version
- **kubectl**: For Kubernetes deployment
- **Git**: Latest version

### System Requirements
- RAM: 8GB minimum (16GB recommended)
- Storage: 5GB free space

## 🔧 Environment Setup

### Task 1: Repository Setup

```bash
# Clone the repository
git clone <repository-url>
cd MLOPSTASK

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt
```

**Success Indicators:**
- ✅ Virtual environment activated
- ✅ All packages installed without errors

## 🤖 Local Development

### Task 2: Train the ML Model

```bash
# Train the model with MLflow tracking
python train_model.py
```

**Expected Output:**
```
Starting ML model training with MLflow tracking...
Dataset Info:
Features shape: (150, 4)
Target classes: ['setosa', 'versicolor', 'virginica']

Training model 1/3 with hyperparams: {'n_estimators': 50, 'max_depth': 5, 'random_state': 42}
Model logged with accuracy: 0.9000

Training completed!
Best model accuracy: 0.9000
MLflow UI: mlflow ui
Models logged to: ./mlruns
```

**Generated Files:**
- `./mlruns/` - MLflow experiment data
- `model.pkl` - Latest trained model
- `best_model.pkl` - Best performing model

### Task 3: Start the API Service

```bash
# Start the Flask API server
python app.py
```

**Expected Output:**
```
INFO:__main__:Initializing ML Inference API...
INFO:__main__:Loaded model from registry: iris-classifier, version: latest
INFO:__main__:Model loaded successfully in 0.61 seconds
INFO:__main__:Starting ML Inference API on port 5000
Available endpoints:
  GET  /health       - Health check
  POST /predict      - Make predictions
  GET  /metrics      - Prometheus metrics
  GET  /model/info   - Model information
  POST /model/reload - Reload model
* Running on http://127.0.0.1:5000
```

### Task 4: Test API Endpoints

Open a new terminal and test:

```bash
# Test health endpoint
curl http://localhost:5000/health

# Test prediction endpoint
curl -X POST http://localhost:5000/predict \
  -H "Content-Type: application/json" \
  -d '{"features": [5.1, 3.5, 1.4, 0.2]}'

# Run comprehensive demo
python demo.py
```

**Expected Prediction Response:**
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
  "timestamp": "2025-09-22T12:57:21Z"
}
```

## 🧪 Testing

### Task 5: Run Unit Tests

```bash
# Run the complete test suite
python -m pytest tests/ -v

# Run with coverage report
python -m pytest tests/ -v --cov=app --cov=train_model --cov-report=html
```

**Expected Output:**
```
============ test session starts ============
collected 14 items

tests/test_api.py::TestHealthEndpoint::test_health_check_success PASSED
tests/test_api.py::TestPredictionEndpoint::test_prediction_success PASSED
...
============== 14 passed in 10.66s ==============
```

## 🐳 Docker Deployment

### Task 6: Build and Run Docker Container

```bash
# Build the Docker image
docker build -t ml-inference-service:latest .

# Run container locally
docker run -d --name ml-api -p 5000:5000 ml-inference-service:latest

# Check container status
docker ps

# Test the containerized API
curl http://localhost:5000/health

# Stop container
docker stop ml-api && docker rm ml-api
```

### Task 7: Docker Compose Multi-Service Setup

```bash
# Start the complete MLOps stack
docker-compose up -d

# Check all services
docker-compose ps

# Access services:
# - API: http://localhost:5001
# - MLflow UI: http://localhost:5000
# - Prometheus: http://localhost:9090
# - Grafana: http://localhost:3000 (admin/admin123)

# Stop all services
docker-compose down
```

## ☸️ Kubernetes Deployment

### Task 8: Prepare Kubernetes Cluster

```bash
# Start minikube (if using minikube)
minikube start --memory=4096 --cpus=2

# Verify cluster
kubectl cluster-info
kubectl get nodes
```

### Task 9: Deploy to Kubernetes

```bash
# Load Docker image to minikube
minikube image load ml-inference-service:latest

# Apply Kubernetes manifests
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Check deployment status
kubectl get deployments
kubectl get pods
kubectl get services
```

### Task 10: Test Kubernetes Deployment

```bash
# Get service URL
minikube service ml-inference-service --url

# Test the service
curl $(minikube service ml-inference-service --url)/health

# Scale the deployment
kubectl scale deployment ml-inference-service --replicas=5
```

### Task 11: Automated Deployment

```bash
# Make deployment script executable (Linux/macOS)
chmod +x deploy.sh

# Run automated deployment
./deploy.sh

# For Windows
.\deploy.ps1
```

## 📊 Monitoring

### Task 12: Access Monitoring Tools

```bash
# Start MLflow UI
mlflow ui --host 0.0.0.0 --port 5000

# Access monitoring dashboards (via docker-compose):
# - MLflow UI: http://localhost:5000
# - Prometheus: http://localhost:9090
# - Grafana: http://localhost:3000
```

### Task 13: Monitor Metrics

```bash
# Generate load to see metrics
for i in {1..100}; do
  curl -X POST http://localhost:5001/predict \
    -H "Content-Type: application/json" \
    -d '{"features": [5.1, 3.5, 1.4, 0.2]}' &
done

# Check Prometheus metrics
curl http://localhost:5001/metrics | grep -E "(api_requests|predictions)"
```

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Model Loading Fails
```bash
# Check if model files exist
ls -la *.pkl mlruns/

# Retrain model
python train_model.py
```

#### API Not Responding
```bash
# Check if process is running
ps aux | grep python
netstat -tulpn | grep 5000

# Run in foreground to see errors
python app.py
```

#### Docker Build Fails
```bash
# Check Dockerfile and rebuild
docker build --no-cache -t ml-inference-service:latest .

# Check disk space
docker system df

# Clean up Docker
docker system prune -af
```

#### Kubernetes Pods Not Starting
```bash
# Check pod logs
kubectl logs -l app=ml-inference-service

# Describe problematic pods
kubectl describe pod <pod-name>

# Check resources
kubectl top nodes
```

### Debug Commands

```bash
# Environment check
python --version
pip list
docker --version
kubectl version

# Port check
netstat -tulpn | grep -E "(5000|5001|9090|3000)"

# Logs
docker logs <container-name>
kubectl logs -f deployment/ml-inference-service
```

## ✅ Quick Start Checklist

1. **Setup Environment**
   - [ ] Clone repository
   - [ ] Create virtual environment
   - [ ] Install dependencies

2. **Train and Test**
   - [ ] Run `python train_model.py`
   - [ ] Run `python app.py`
   - [ ] Run `python demo.py`
   - [ ] Run `python -m pytest tests/ -v`

3. **Docker Deployment**
   - [ ] Run `docker build -t ml-inference-service:latest .`
   - [ ] Run `docker run -d --name ml-api -p 5000:5000 ml-inference-service:latest`
   - [ ] Test with `curl http://localhost:5000/health`

4. **Kubernetes Deployment**
   - [ ] Run `minikube start`
   - [ ] Run `./deploy.sh` (or `.\deploy.ps1` on Windows)
   - [ ] Test with `curl $(minikube service ml-inference-service --url)/health`

5. **Monitoring**
   - [ ] Run `docker-compose up -d`
   - [ ] Access Grafana at http://localhost:3000
   - [ ] Access MLflow at http://localhost:5000

## 🚀 Production Deployment

For production deployment:

1. **Security**: Enable HTTPS, authentication, and network policies
2. **Scaling**: Configure auto-scaling and load balancing
3. **Monitoring**: Set up comprehensive logging and alerting
4. **CI/CD**: Use the provided GitHub Actions workflow
5. **Backup**: Implement model and data backup strategies

## 📞 Support

For issues or questions:
1. Check the [Troubleshooting](#-troubleshooting) section
2. Review container/pod logs
3. Verify all prerequisites are installed
4. Test each component individually

**Project Created by: Bharath Kumar**