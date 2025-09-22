# MLOps Inference Service

**Created by: Bharath Kumar**

A production-ready ML inference service built with Flask, MLflow, Docker, Kubernetes, and comprehensive monitoring capabilities.

## 🚀 Quick Start

### Option 1: Local Development
```bash
# 1. Setup environment
python -m venv venv
venv\Scripts\activate  # Windows
# source venv/bin/activate  # Linux/macOS
pip install -r requirements.txt

# 2. Train model
python train_model.py

# 3. Start API
python app.py

# 4. Test API
python demo.py
```

### Option 2: Docker Deployment
```bash
# 1. Build and run
docker build -t ml-inference-service .
docker run -d --name ml-api -p 5000:5000 ml-inference-service

# 2. Test
curl http://localhost:5000/health
```

### Option 3: Kubernetes Deployment
```bash
# Automated deployment
./deploy.sh  # Linux/macOS
.\deploy.ps1  # Windows
```

### Option 4: Complete MLOps Stack
```bash
# Start full monitoring stack
docker-compose up -d

# Access services:
# - API: http://localhost:5001
# - MLflow: http://localhost:5000
# - Prometheus: http://localhost:9090
# - Grafana: http://localhost:3000
```

## 📚 Documentation

- **[Task Execution Guide](TASK_EXECUTION_GUIDE.md)**: Comprehensive step-by-step instructions
- **[Implementation Summary](IMPLEMENTATION_SUMMARY.md)**: Detailed project overview and results

## 🎯 Features

### ML Model
- **Algorithm**: Random Forest Classifier
- **Dataset**: Iris classification (3 classes)
- **Accuracy**: 90%+ on test data
- **Versioning**: MLflow model registry

### API Endpoints
- `GET /health` - Service health check
- `POST /predict` - Model predictions
- `GET /metrics` - Prometheus metrics
- `GET /model/info` - Model information
- `POST /model/reload` - Reload model

### Production Features
- **Containerization**: Docker with security best practices
- **Orchestration**: Kubernetes with auto-scaling
- **Monitoring**: Prometheus metrics + Grafana dashboards
- **CI/CD**: GitHub Actions pipeline
- **Testing**: Comprehensive test suite (14 tests)
- **Security**: Non-root containers, vulnerability scanning

## 🧪 Testing

```bash
# Run all tests
python -m pytest tests/ -v

# Run with coverage
python -m pytest tests/ -v --cov=app --cov-report=html

# API demonstration
python demo.py
```

## 📊 Example Usage

### Health Check
```bash
curl http://localhost:5000/health
```

### Make Prediction
```bash
curl -X POST http://localhost:5000/predict \
  -H "Content-Type: application/json" \
  -d '{"features": [5.1, 3.5, 1.4, 0.2]}'
```

### Expected Response
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
  "input_features": {
    "sepal length (cm)": 5.1,
    "sepal width (cm)": 3.5,
    "petal length (cm)": 1.4,
    "petal width (cm)": 0.2
  }
}
```