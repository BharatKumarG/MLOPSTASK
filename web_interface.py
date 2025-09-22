#!/usr/bin/env python3
"""
Web Interface for ML Inference API
Provides a browser-based dashboard for testing and monitoring the ML service
"""

from flask import Flask, render_template, request, jsonify, redirect, url_for
import requests
import json
import time
import threading
from datetime import datetime
import os

# Create Flask app for web interface
web_app = Flask(__name__, template_folder='templates', static_folder='static')

# Add custom Jinja2 filters
from datetime import datetime

def strftime_filter(timestamp, format='%Y-%m-%d %H:%M:%S'):
    """Custom strftime filter for Jinja2 templates"""
    if isinstance(timestamp, str):
        return timestamp
    return timestamp.strftime(format)

web_app.jinja_env.filters['strftime'] = strftime_filter

# Configuration
API_BASE_URL = "http://localhost:5000"
SAMPLE_PREDICTIONS = [
    {"features": [5.1, 3.5, 1.4, 0.2], "expected": "setosa", "description": "Typical Setosa"},
    {"features": [7.0, 3.2, 4.7, 1.4], "expected": "versicolor", "description": "Typical Versicolor"},  
    {"features": [6.3, 3.3, 6.0, 2.5], "expected": "virginica", "description": "Typical Virginica"},
    {"features": [4.9, 3.0, 1.4, 0.2], "expected": "setosa", "description": "Small Setosa"},
    {"features": [6.4, 3.2, 4.5, 1.5], "expected": "versicolor", "description": "Medium Versicolor"},
    {"features": [6.9, 3.1, 5.4, 2.1], "expected": "virginica", "description": "Large Virginica"},
]

# Global variables to store test results
test_results = {}
api_status = {"healthy": False, "last_check": None}

def check_api_health():
    """Check if the API is healthy"""
    try:
        response = requests.get(f"{API_BASE_URL}/health", timeout=5)
        if response.status_code == 200:
            data = response.json()
            api_status.update({
                "healthy": True,
                "last_check": datetime.now(),
                "status": data.get('status'),
                "model_loaded": data.get('model_loaded'),
                "version": data.get('version')
            })
            return True
    except Exception as e:
        api_status.update({
            "healthy": False,
            "last_check": datetime.now(),
            "error": str(e)
        })
    return False

def run_comprehensive_tests():
    """Run comprehensive tests and store results"""
    global test_results
    
    test_results = {
        "timestamp": datetime.now(),
        "health": {"status": "running", "details": {}},
        "model_info": {"status": "running", "details": {}},
        "predictions": {"status": "running", "details": {}},
        "error_handling": {"status": "running", "details": {}},
        "performance": {"status": "running", "details": {}},
        "metrics": {"status": "running", "details": {}}
    }
    
    # Health test
    try:
        response = requests.get(f"{API_BASE_URL}/health", timeout=10)
        if response.status_code == 200:
            data = response.json()
            test_results["health"] = {
                "status": "passed",
                "details": data
            }
        else:
            test_results["health"] = {
                "status": "failed",
                "details": {"error": f"Status code: {response.status_code}"}
            }
    except Exception as e:
        test_results["health"] = {
            "status": "failed",
            "details": {"error": str(e)}
        }
    
    # Model info test
    try:
        response = requests.get(f"{API_BASE_URL}/model/info", timeout=10)
        if response.status_code == 200:
            data = response.json()
            test_results["model_info"] = {
                "status": "passed",
                "details": data
            }
        else:
            test_results["model_info"] = {
                "status": "failed",
                "details": {"error": f"Status code: {response.status_code}"}
            }
    except Exception as e:
        test_results["model_info"] = {
            "status": "failed",
            "details": {"error": str(e)}
        }
    
    # Prediction tests
    correct_predictions = 0
    prediction_details = []
    
    for sample in SAMPLE_PREDICTIONS:
        try:
            response = requests.post(
                f"{API_BASE_URL}/predict",
                json={"features": sample["features"]},
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                predicted_class = data["prediction"]["class_name"]
                confidence = data["prediction"]["confidence"]
                is_correct = predicted_class == sample["expected"]
                
                if is_correct:
                    correct_predictions += 1
                
                prediction_details.append({
                    "description": sample["description"],
                    "features": sample["features"],
                    "expected": sample["expected"],
                    "predicted": predicted_class,
                    "confidence": confidence,
                    "correct": is_correct,
                    "probabilities": data["probabilities"]
                })
            else:
                prediction_details.append({
                    "description": sample["description"],
                    "features": sample["features"],
                    "expected": sample["expected"],
                    "error": f"Status code: {response.status_code}"
                })
                
        except Exception as e:
            prediction_details.append({
                "description": sample["description"],
                "features": sample["features"],
                "expected": sample["expected"],
                "error": str(e)
            })
    
    accuracy = correct_predictions / len(SAMPLE_PREDICTIONS)
    test_results["predictions"] = {
        "status": "passed" if accuracy > 0.8 else "failed",
        "details": {
            "accuracy": accuracy,
            "correct": correct_predictions,
            "total": len(SAMPLE_PREDICTIONS),
            "predictions": prediction_details
        }
    }
    
    # Error handling tests
    error_cases = [
        {"name": "Missing features", "data": {"wrong_field": [1, 2, 3, 4]}},
        {"name": "Wrong feature count", "data": {"features": [1, 2, 3]}},
        {"name": "Non-numeric features", "data": {"features": ["a", "b", "c", "d"]}},
        {"name": "Empty features", "data": {"features": []}},
    ]
    
    error_results = []
    for case in error_cases:
        try:
            response = requests.post(
                f"{API_BASE_URL}/predict",
                json=case["data"],
                timeout=10
            )
            
            error_results.append({
                "name": case["name"],
                "expected_status": 400,
                "actual_status": response.status_code,
                "passed": response.status_code == 400,
                "error_message": response.json().get("error", "No error message") if response.status_code == 400 else None
            })
        except Exception as e:
            error_results.append({
                "name": case["name"],
                "error": str(e),
                "passed": False
            })
    
    error_passed = all(result.get("passed", False) for result in error_results)
    test_results["error_handling"] = {
        "status": "passed" if error_passed else "failed",
        "details": {"tests": error_results}
    }
    
    # Performance test
    start_time = time.time()
    successful_requests = 0
    total_requests = 20  # Reduced for web interface
    
    for _ in range(total_requests):
        sample = SAMPLE_PREDICTIONS[0]  # Use first sample for consistency
        try:
            response = requests.post(
                f"{API_BASE_URL}/predict",
                json={"features": sample["features"]},
                timeout=5
            )
            if response.status_code == 200:
                successful_requests += 1
        except:
            pass
    
    end_time = time.time()
    total_time = end_time - start_time
    
    test_results["performance"] = {
        "status": "passed" if successful_requests >= (total_requests * 0.9) else "failed",
        "details": {
            "total_time": total_time,
            "successful_requests": successful_requests,
            "total_requests": total_requests,
            "avg_response_time": (total_time / total_requests) * 1000,
            "requests_per_second": total_requests / total_time
        }
    }
    
    # Metrics test
    try:
        response = requests.get(f"{API_BASE_URL}/metrics", timeout=10)
        if response.status_code == 200:
            metrics_text = response.text
            metric_lines = [line for line in metrics_text.split('\n') if line and not line.startswith('#')]
            sample_metrics = metrics_text.split('\n')[:20]
            
            test_results["metrics"] = {
                "status": "passed",
                "details": {
                    "total_metrics": len(metric_lines),
                    "sample_metrics": sample_metrics
                }
            }
        else:
            test_results["metrics"] = {
                "status": "info",
                "details": {"message": "Metrics endpoint not available (Prometheus may not be installed)"}
            }
    except Exception as e:
        test_results["metrics"] = {
            "status": "info",
            "details": {"message": f"Metrics not accessible: {str(e)}"}
        }

@web_app.route('/')
def dashboard():
    """Main dashboard page"""
    check_api_health()
    return render_template('dashboard.html', 
                         api_status=api_status, 
                         test_results=test_results,
                         sample_predictions=SAMPLE_PREDICTIONS,
                         datetime=datetime)

@web_app.route('/run_tests')
def run_tests():
    """Run comprehensive tests"""
    # Run tests in background thread
    thread = threading.Thread(target=run_comprehensive_tests)
    thread.daemon = True
    thread.start()
    
    return redirect(url_for('dashboard'))

@web_app.route('/api/predict', methods=['POST'])
def api_predict():
    """Proxy endpoint for predictions with CORS support"""
    try:
        data = request.get_json()
        response = requests.post(f"{API_BASE_URL}/predict", json=data, timeout=10)
        return jsonify(response.json()), response.status_code
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@web_app.route('/api/health')
def api_health():
    """Get current API health status"""
    check_api_health()
    return jsonify(api_status)

@web_app.route('/api/test_results')
def get_test_results():
    """Get current test results"""
    return jsonify(test_results)

if __name__ == '__main__':
    # Create templates directory if it doesn't exist
    os.makedirs('templates', exist_ok=True)
    os.makedirs('static', exist_ok=True)
    
    print("Starting ML Inference Web Interface...")
    print("API Endpoint:", API_BASE_URL)
    print("Web Interface will be available at: http://localhost:8080")
    
    web_app.run(host='0.0.0.0', port=8080, debug=True)