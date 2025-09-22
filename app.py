# app.py

import os
import json
import time
import logging
from datetime import datetime, timezone
from flask import Flask, request, jsonify
import numpy as np
import pandas as pd
import pickle
from sklearn.preprocessing import StandardScaler

# Try to import MLflow, fallback to basic model loading if not available
try:
    import mlflow
    import mlflow.sklearn
    MLFLOW_AVAILABLE = True
except ImportError:
    print("MLflow not available. Using basic model loading.")
    MLFLOW_AVAILABLE = False

# Try to import Prometheus, make it optional
try:
    from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
    PROMETHEUS_AVAILABLE = True
except ImportError:
    print("Prometheus client not available. Metrics disabled.")
    PROMETHEUS_AVAILABLE = False

# Initialize Flask app
app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Prometheus metrics (optional)
if PROMETHEUS_AVAILABLE:
    REQUEST_COUNT = Counter('api_requests_total', 'Total API requests', ['method', 'endpoint', 'status'])
    REQUEST_LATENCY = Histogram('api_request_duration_seconds', 'API request latency')
    PREDICTION_COUNT = Counter('predictions_total', 'Total predictions made', ['model_version'])
    MODEL_LOAD_TIME = Histogram('model_load_duration_seconds', 'Model loading time')
else:
    # Dummy metrics when Prometheus is not available
    class DummyCounter:
        def inc(self): pass
        def labels(self, **kwargs): return self
    
    class DummyHistogram:
        def observe(self, value): pass
    
    REQUEST_COUNT = DummyCounter()
    REQUEST_LATENCY = DummyHistogram()
    PREDICTION_COUNT = DummyCounter()
    MODEL_LOAD_TIME = DummyHistogram()

# Global variables for model and metadata
model = None
model_version = None
model_info = None
scaler = None
feature_names = ['sepal length (cm)', 'sepal width (cm)', 'petal length (cm)', 'petal width (cm)']
target_names = ['setosa', 'versicolor', 'virginica']

def load_model_from_mlflow():
    """Load the latest model from MLflow model registry or local file"""
    global model, model_version, model_info, scaler
    
    start_time = time.time()
    try:
        if MLFLOW_AVAILABLE:
            # Set MLflow tracking URI
            mlflow.set_tracking_uri("file:./mlruns")
            
            # Try to load from model registry first
            try:
                model_name = "iris-classifier"
                model_version = "latest"
                model_uri = f"models:/{model_name}/{model_version}"
                model = mlflow.sklearn.load_model(model_uri)
                model_info = {
                    "source": "model_registry",
                    "name": model_name,
                    "version": model_version
                }
                logger.info(f"Loaded model from registry: {model_name}, version: {model_version}")
            except Exception as e:
                logger.warning(f"Could not load from model registry: {e}")
                # Fallback to loading latest run
                experiment_name = "iris-classification"
                experiment = mlflow.get_experiment_by_name(experiment_name)
                
                if experiment:
                    runs = mlflow.search_runs(experiment_ids=[experiment.experiment_id])
                    if not runs.empty:
                        # Get the best run (highest accuracy)
                        best_run = runs.loc[runs['metrics.accuracy'].idxmax()]
                        run_id = best_run['run_id']
                        model_uri = f"runs:/{run_id}/model"
                        model = mlflow.sklearn.load_model(model_uri)
                        model_info = {
                            "source": "experiment_run",
                            "run_id": run_id,
                            "accuracy": best_run['metrics.accuracy']
                        }
                        model_version = run_id[:8]  # Use first 8 chars of run_id as version
                        logger.info(f"Loaded model from run: {run_id}, accuracy: {best_run['metrics.accuracy']:.4f}")
                    else:
                        raise Exception("No trained models found in MLflow")
                else:
                    raise Exception("Experiment 'iris-classification' not found")
        else:
            # Load from local pickle file
            model_files = ['best_model.pkl', 'model.pkl']
            model_loaded = False
            
            for model_file in model_files:
                if os.path.exists(model_file):
                    with open(model_file, 'rb') as f:
                        model = pickle.load(f)
                    model_info = {
                        "source": "local_file",
                        "file": model_file
                    }
                    model_version = "local"
                    logger.info(f"Loaded model from local file: {model_file}")
                    model_loaded = True
                    break
            
            if not model_loaded:
                raise Exception("No model files found. Please train a model first.")
        
        # Initialize scaler (in production, this should also be saved with MLflow)
        scaler = StandardScaler()
        # Fit scaler with dummy data based on Iris dataset statistics
        dummy_data = np.array([
            [5.1, 3.5, 1.4, 0.2],  # Typical setosa
            [7.0, 3.2, 4.7, 1.4],  # Typical versicolor
            [6.3, 3.3, 6.0, 2.5]   # Typical virginica
        ])
        scaler.fit(dummy_data)
        
        load_time = time.time() - start_time
        MODEL_LOAD_TIME.observe(load_time)
        
        logger.info(f"Model loaded successfully in {load_time:.2f} seconds")
        logger.info(f"Model info: {model_info}")
        
        return True
        
    except Exception as e:
        logger.error(f"Failed to load model: {e}")
        return False

# Initialize model on startup
with app.app_context():
    def initialize():
        """Initialize the application"""
        logger.info("Initializing ML Inference API...")
        success = load_model_from_mlflow()
        if not success:
            logger.error("Failed to load model. API will not function properly.")
    
    initialize()

@app.before_request
def before_request():
    """Log request start time"""
    request.start_time = time.time()

@app.after_request
def after_request(response):
    """Log request metrics"""
    try:
        latency = time.time() - request.start_time
        REQUEST_LATENCY.observe(latency)
        REQUEST_COUNT.labels(
            method=request.method,
            endpoint=request.endpoint or 'unknown',
            status=response.status_code
        ).inc()
    except:
        pass  # Don't let metrics collection break the response
    return response

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    try:
        status = {
            "status": "healthy",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "model_loaded": model is not None,
            "model_info": model_info,
            "version": "1.0.0"
        }
        
        if model is None:
            status["status"] = "unhealthy"
            status["error"] = "Model not loaded"
            return jsonify(status), 503
        
        return jsonify(status), 200
        
    except Exception as e:
        return jsonify({
            "status": "error",
            "error": str(e),
            "timestamp": datetime.now(timezone.utc).isoformat()
        }), 500

@app.route('/predict', methods=['POST'])
def predict():
    """Prediction endpoint"""
    try:
        # Check if model is loaded
        if model is None:
            return jsonify({
                "error": "Model not loaded",
                "message": "Please ensure the model is properly trained and available"
            }), 503
        
        # Get request data
        data = request.get_json(force=True, silent=True)
        
        if not data:
            return jsonify({
                "error": "No JSON data provided or invalid JSON format",
                "message": "Please provide valid JSON with 'features' field"
            }), 400
        
        # Validate input format
        if 'features' not in data:
            return jsonify({
                "error": "Missing 'features' field",
                "expected_format": {
                    "features": [5.1, 3.5, 1.4, 0.2]
                }
            }), 400
        
        features = data['features']
        
        # Validate features
        if not isinstance(features, list) or len(features) != 4:
            return jsonify({
                "error": "Features must be a list of 4 numeric values",
                "feature_names": feature_names,
                "provided": features
            }), 400
        
        # Convert to numpy array and validate numeric values
        try:
            features_array = np.array(features, dtype=float).reshape(1, -1)
        except ValueError:
            return jsonify({
                "error": "All features must be numeric",
                "provided": features
            }), 400
        
        # Scale features
        if scaler is not None:
            features_scaled = scaler.transform(features_array)
        else:
            features_scaled = features_array
        
        # Make prediction
        prediction = model.predict(features_scaled)[0]
        prediction_proba = model.predict_proba(features_scaled)[0]
        
        # Prepare response
        response_data = {
            "prediction": {
                "class_id": int(prediction),
                "class_name": target_names[prediction],
                "confidence": float(max(prediction_proba))
            },
            "probabilities": {
                target_names[i]: float(prob) 
                for i, prob in enumerate(prediction_proba)
            },
            "input_features": {
                feature_names[i]: float(features[i]) 
                for i in range(len(features))
            },
            "model_info": model_info,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        # Update metrics
        PREDICTION_COUNT.labels(model_version=model_version or 'unknown').inc()
        
        # Log prediction for monitoring
        logger.info(f"Prediction made: {target_names[prediction]} (confidence: {max(prediction_proba):.3f})")
        
        return jsonify(response_data), 200
        
    except Exception as e:
        logger.error(f"Prediction error: {e}")
        return jsonify({
            "error": "Internal server error",
            "message": str(e),
            "timestamp": datetime.utcnow().isoformat()
        }), 500

@app.route('/metrics', methods=['GET'])
def metrics():
    """Prometheus metrics endpoint"""
    if PROMETHEUS_AVAILABLE:
        return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}
    else:
        return jsonify({"error": "Prometheus metrics not available"}), 503

@app.route('/model/info', methods=['GET'])
def model_info_endpoint():
    """Get model information"""
    if model is None:
        return jsonify({"error": "Model not loaded"}), 503
    
    return jsonify({
        "model_info": model_info,
        "feature_names": feature_names,
        "target_names": target_names,
        "model_type": type(model).__name__,
        "timestamp": datetime.utcnow().isoformat()
    }), 200

@app.route('/model/reload', methods=['POST'])
def reload_model():
    """Reload model from MLflow"""
    try:
        success = load_model_from_mlflow()
        if success:
            return jsonify({
                "message": "Model reloaded successfully",
                "model_info": model_info,
                "timestamp": datetime.utcnow().isoformat()
            }), 200
        else:
            return jsonify({
                "error": "Failed to reload model",
                "timestamp": datetime.utcnow().isoformat()
            }), 500
    except Exception as e:
        return jsonify({
            "error": str(e),
            "timestamp": datetime.now(timezone.utc).isoformat()
        }), 500

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return jsonify({
        "error": "Not found",
        "message": "The requested endpoint does not exist",
        "available_endpoints": [
            "/health",
            "/predict",
            "/metrics",
            "/model/info",
            "/model/reload"
        ]
    }), 404

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    return jsonify({
        "error": "Internal server error",
        "message": "An unexpected error occurred"
    }), 500

if __name__ == '__main__':
    # Load model on startup
    load_model_from_mlflow()
    
    # Run the app
    port = int(os.environ.get('PORT', 5000))
    debug = os.environ.get('DEBUG', 'False').lower() == 'true'
    
    logger.info(f"Starting ML Inference API on port {port}")
    logger.info("Available endpoints:")
    logger.info("  GET  /health       - Health check")
    logger.info("  POST /predict      - Make predictions")
    logger.info("  GET  /metrics      - Prometheus metrics")
    logger.info("  GET  /model/info   - Model information")
    logger.info("  POST /model/reload - Reload model")
    
    app.run(host='0.0.0.0', port=port, debug=debug)