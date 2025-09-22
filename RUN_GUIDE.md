# 🚀 Step-by-Step Project Execution Guide

This guide shows you how to run each component of the ML Inference project one by one.

## 📋 Prerequisites

Before running any component, ensure you have:
- Python 3.7+ installed
- Required packages installed: `pip install -r requirements.txt`

## 🎯 Component Execution Order

### Step 1: Train the ML Model
**Purpose:** Create and train the iris classification model

```powershell
# Navigate to project directory
cd "d:\GitCloneDESKTOP APP\My-Android-App\MLOPSTASK"

# Run the training script
python train_model.py
```

**What this does:**
- Loads the iris dataset
- Trains multiple ML models (Random Forest, SVM, Logistic Regression)
- Saves the best model using MLflow
- Creates model versioning and metadata

**Expected Output:**
- Model training logs
- MLflow experiment tracking
- Best model saved to MLflow registry

---

### Step 2: Start the ML API Service
**Purpose:** Launch the Flask API that serves ML predictions

```powershell
# Make sure you're in the project directory
cd "d:\GitCloneDESKTOP APP\My-Android-App\MLOPSTASK"

# Start the API server
python app.py
```

**What this does:**
- Loads the trained model from MLflow
- Starts Flask web server on port 5000
- Provides REST API endpoints for predictions
- Enables health monitoring and metrics

**Available Endpoints:**
- `GET /health` - Health check
- `POST /predict` - Make predictions
- `GET /model/info` - Model information
- `GET /metrics` - Prometheus metrics

**Expected Output:**
```
INFO:__main__:Initializing ML Inference API...
INFO:__main__:Model loaded successfully
INFO:__main__:Starting ML Inference API on port 5000
* Running on http://127.0.0.1:5000
```

---

### Step 3: Test the API (Command Line)
**Purpose:** Verify the API works correctly with comprehensive tests

**Option A: Run Demo Script**
```powershell
# In a NEW terminal window
cd "d:\GitCloneDESKTOP APP\My-Android-App\MLOPSTASK"

# Run the demo/testing script
python demo.py
```

**Option B: Manual API Testing**
```powershell
# Test health endpoint
curl http://localhost:5000/health

# Test prediction (using PowerShell)
Invoke-RestMethod -Uri "http://localhost:5000/predict" -Method POST -ContentType "application/json" -Body '{"features": [5.1, 3.5, 1.4, 0.2]}'
```

---

### Step 4: Launch Web Dashboard
**Purpose:** Provide browser-based interface for testing and monitoring

```powershell
# In a NEW terminal window
cd "d:\GitCloneDESKTOP APP\My-Android-App\MLOPSTASK"

# Start the web interface
python web_interface.py
```

**What this provides:**
- Browser dashboard at http://localhost:8080
- Interactive testing interface
- Real-time API monitoring
- Visual test results
- Performance metrics

---

### Step 5: API Testing with Real Requests
**Purpose:** Test the API with various scenarios

```powershell
# In a NEW terminal window
cd "d:\GitCloneDESKTOP APP\My-Android-App\MLOPSTASK"

# Run comprehensive API tests
python tests/test_api.py
```

---

### Step 6: Docker Deployment (Optional)
**Purpose:** Containerize the application

```powershell
# Build Docker image
docker build -t ml-inference .

# Run Docker container
docker run -p 5000:5000 ml-inference
```

---

### Step 7: Kubernetes Deployment (Optional)
**Purpose:** Deploy to Kubernetes cluster

```powershell
# Apply Kubernetes configurations
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Check deployment status
kubectl get pods
kubectl get services
```

---

## 🛠️ Individual Component Commands

### Just Train Model:
```powershell
python train_model.py
```

### Just Start API:
```powershell
python app.py
```

### Just Test API:
```powershell
python demo.py
```

### Just Web Interface:
```powershell
python web_interface.py
```

### Just Run Tests:
```powershell
python -m pytest tests/ -v
```

---

## 🔧 Troubleshooting

### If Model Training Fails:
```powershell
# Check if MLflow is installed
pip install mlflow

# Clear previous runs if needed
rm -rf mlruns
python train_model.py
```

### If API Won't Start:
```powershell
# Check if port 5000 is available
netstat -an | findstr 5000

# Try different port
$env:PORT="5001"
python app.py
```

### If Web Interface Won't Start:
```powershell
# Check if port 8080 is available
netstat -an | findstr 8080

# Edit web_interface.py to use different port
# Change: web_app.run(host='0.0.0.0', port=8080, debug=True)
# To:     web_app.run(host='0.0.0.0', port=8081, debug=True)
```

---

## 📊 Monitoring and Logs

### View API Logs:
- API logs appear in the terminal where you ran `python app.py`
- Check MLflow UI: http://localhost:5000 (if MLflow server is running)

### View Model Performance:
```powershell
# Start MLflow UI
mlflow ui

# Access at: http://localhost:5000
```

### View Metrics:
- Prometheus metrics: http://localhost:5000/metrics
- Web dashboard: http://localhost:8080

---

## 🎯 Quick Start Commands

### Minimal Setup (API Only):
```powershell
cd "d:\GitCloneDESKTOP APP\My-Android-App\MLOPSTASK"
python train_model.py
python app.py
```

### Full Setup (API + Web Interface):
```powershell
# Terminal 1: API
cd "d:\GitCloneDESKTOP APP\My-Android-App\MLOPSTASK"
python app.py

# Terminal 2: Web Interface
cd "d:\GitCloneDESKTOP APP\My-Android-App\MLOPSTASK"
python web_interface.py

# Terminal 3: Testing
cd "d:\GitCloneDESKTOP APP\My-Android-App\MLOPSTASK"
python demo.py
```

---

## 📝 Notes

1. **Order Matters:** Always train the model before starting the API
2. **Multiple Terminals:** Use separate terminal windows for each service
3. **Port Conflicts:** Ensure ports 5000 and 8080 are available
4. **Dependencies:** Install requirements.txt before running any component
5. **MLflow:** Model training creates MLflow artifacts that the API depends on

---

**Happy Machine Learning! 🤖✨**