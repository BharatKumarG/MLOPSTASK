# MLOps Inference Service

A production-ready ML inference service built with Flask, MLflow, Kubernetes, and monitoring capabilities.

## Project Structure

```
.
├── app.py                    # Flask API application
├── train_model.py           # Model training with MLflow tracking
├── requirements.txt         # Python dependencies
├── Dockerfile              # Container configuration
├── docker-compose.yml      # MLflow tracking server setup
├── prometheus.yml          # Prometheus configuration
├── deploy.sh              # Deployment automation script
├── k8s/                   # Kubernetes manifests
│   ├── deployment.yaml
│   └── service.yaml
├── .github/               # GitHub Actions CI/CD
│   └── workflows/
│       └── deploy.yml
└── tests/                 # API tests
    └── test_api.py
```

## Quick Start

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Train the model:
```bash
python train_model.py
```

3. Start the API:
```bash
python app.py
```

4. Test the API:
```bash
curl -X POST http://localhost:5000/predict \
  -H "Content-Type: application/json" \
  -d '{"features": [5.1, 3.5, 1.4, 0.2]}'
```


## Endpoints

- `GET /health` - Health check endpoint
- `POST /predict` - Model prediction endpoint
- `GET /metrics` - Prometheus metrics endpoint

## Deployment

Use the automated deployment script:
```bash
./deploy.sh
```

Or deploy manually:
```bash
docker build -t ml-inference-service .
kubectl apply -f k8s/
```