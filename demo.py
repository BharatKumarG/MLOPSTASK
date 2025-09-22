#!/usr/bin/env python3
"""
Demo Script for ML Inference API
Demonstrates the functionality of the deployed ML service
"""

import requests
import json
import time
import random
from datetime import datetime

# Configuration
API_BASE_URL = "http://localhost:5000"  # Change this to your deployed endpoint
SAMPLE_PREDICTIONS = [
    {"features": [5.1, 3.5, 1.4, 0.2], "expected": "setosa"},
    {"features": [7.0, 3.2, 4.7, 1.4], "expected": "versicolor"},  
    {"features": [6.3, 3.3, 6.0, 2.5], "expected": "virginica"},
    {"features": [4.9, 3.0, 1.4, 0.2], "expected": "setosa"},
    {"features": [6.4, 3.2, 4.5, 1.5], "expected": "versicolor"},
    {"features": [6.9, 3.1, 5.4, 2.1], "expected": "virginica"},
]

def print_header(title):
    """Print a formatted header"""
    print("\n" + "="*60)
    print(f" {title}")
    print("="*60)

def print_success(message):
    """Print success message"""
    print(f"✅ {message}")

def print_error(message):
    """Print error message"""
    print(f"❌ {message}")

def print_info(message):
    """Print info message"""
    print(f"ℹ️  {message}")

def test_health_endpoint():
    """Test the health endpoint"""
    print_header("Testing Health Endpoint")
    
    try:
        response = requests.get(f"{API_BASE_URL}/health", timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            print_success("Health check passed!")
            print(f"   Status: {data.get('status')}")
            print(f"   Model loaded: {data.get('model_loaded')}")
            print(f"   Version: {data.get('version')}")
            print(f"   Timestamp: {data.get('timestamp')}")
            return True
        else:
            print_error(f"Health check failed with status: {response.status_code}")
            return False
            
    except requests.exceptions.RequestException as e:
        print_error(f"Health check failed: {e}")
        return False

def test_model_info():
    """Test the model info endpoint"""
    print_header("Testing Model Info Endpoint")
    
    try:
        response = requests.get(f"{API_BASE_URL}/model/info", timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            print_success("Model info retrieved successfully!")
            print(f"   Model type: {data.get('model_type')}")
            print(f"   Features: {', '.join(data.get('feature_names', []))}")
            print(f"   Classes: {', '.join(data.get('target_names', []))}")
            return True
        else:
            print_error(f"Model info failed with status: {response.status_code}")
            return False
            
    except requests.exceptions.RequestException as e:
        print_error(f"Model info failed: {e}")
        return False

def test_predictions():
    """Test prediction endpoint with sample data"""
    print_header("Testing Prediction Endpoint")
    
    correct_predictions = 0
    total_predictions = len(SAMPLE_PREDICTIONS)
    
    for i, sample in enumerate(SAMPLE_PREDICTIONS, 1):
        print(f"\n🔍 Test Case {i}/{total_predictions}")
        print(f"   Input: {sample['features']}")
        print(f"   Expected: {sample['expected']}")
        
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
                
                print(f"   Predicted: {predicted_class} (confidence: {confidence:.3f})")
                
                if predicted_class == sample["expected"]:
                    print_success("Correct prediction!")
                    correct_predictions += 1
                else:
                    print_error("Incorrect prediction!")
                
                # Show probabilities
                probs = data["probabilities"]
                print(f"   Probabilities: {json.dumps(probs, indent=6)}")
                
            else:
                print_error(f"Prediction failed with status: {response.status_code}")
                print(f"   Response: {response.text}")
                
        except requests.exceptions.RequestException as e:
            print_error(f"Prediction failed: {e}")
    
    accuracy = correct_predictions / total_predictions
    print(f"\n📊 Accuracy: {correct_predictions}/{total_predictions} ({accuracy:.1%})")
    
    return accuracy > 0.8  # Consider success if >80% accuracy

def test_error_handling():
    """Test error handling with invalid inputs"""
    print_header("Testing Error Handling")
    
    error_cases = [
        {"name": "Missing features", "data": {"wrong_field": [1, 2, 3, 4]}},
        {"name": "Wrong feature count", "data": {"features": [1, 2, 3]}},
        {"name": "Non-numeric features", "data": {"features": ["a", "b", "c", "d"]}},
        {"name": "Empty features", "data": {"features": []}},
    ]
    
    success_count = 0
    
    for case in error_cases:
        print(f"\n🧪 Testing: {case['name']}")
        
        try:
            response = requests.post(
                f"{API_BASE_URL}/predict",
                json=case["data"],
                timeout=10
            )
            
            if response.status_code == 400:
                print_success("Correctly returned 400 error")
                error_data = response.json()
                print(f"   Error message: {error_data.get('error', 'No error message')}")
                success_count += 1
            else:
                print_error(f"Expected 400, got {response.status_code}")
                
        except requests.exceptions.RequestException as e:
            print_error(f"Request failed: {e}")
    
    return success_count == len(error_cases)

def performance_test():
    """Run a basic performance test"""
    print_header("Performance Testing")
    
    print_info("Running 50 prediction requests...")
    
    start_time = time.time()
    successful_requests = 0
    total_requests = 50
    
    for i in range(total_requests):
        # Use random sample
        sample = random.choice(SAMPLE_PREDICTIONS)
        
        try:
            response = requests.post(
                f"{API_BASE_URL}/predict",
                json={"features": sample["features"]},
                timeout=5
            )
            
            if response.status_code == 200:
                successful_requests += 1
            
            if (i + 1) % 10 == 0:
                print(f"   Completed {i + 1}/{total_requests} requests...")
                
        except requests.exceptions.RequestException:
            pass  # Count as failed request
    
    end_time = time.time()
    total_time = end_time - start_time
    
    print(f"\n📈 Performance Results:")
    print(f"   Total time: {total_time:.2f} seconds")
    print(f"   Successful requests: {successful_requests}/{total_requests}")
    print(f"   Average response time: {(total_time/total_requests)*1000:.1f} ms")
    print(f"   Requests per second: {total_requests/total_time:.1f}")
    
    return successful_requests >= (total_requests * 0.95)  # 95% success rate

def test_metrics_endpoint():
    """Test the metrics endpoint"""
    print_header("Testing Metrics Endpoint")
    
    try:
        response = requests.get(f"{API_BASE_URL}/metrics", timeout=10)
        
        if response.status_code == 200:
            print_success("Metrics endpoint accessible!")
            metrics_text = response.text
            
            # Count metrics
            metric_lines = [line for line in metrics_text.split('\n') if line and not line.startswith('#')]
            print(f"   Found {len(metric_lines)} metrics")
            
            # Show sample metrics
            print("   Sample metrics:")
            for line in metrics_text.split('\n')[:10]:
                if line and not line.startswith('#'):
                    print(f"     {line}")
            
            return True
        else:
            print_info(f"Metrics endpoint returned status: {response.status_code}")
            print_info("This might be expected if Prometheus is not available")
            return True  # Don't fail on this
            
    except requests.exceptions.RequestException as e:
        print_info(f"Metrics endpoint not accessible: {e}")
        return True  # Don't fail on this

def main():
    """Main demonstration function"""
    print_header("ML Inference API Demonstration")
    print(f"Testing API at: {API_BASE_URL}")
    print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Track test results
    test_results = {}
    
    # Run all tests
    test_results["health"] = test_health_endpoint()
    test_results["model_info"] = test_model_info()
    test_results["predictions"] = test_predictions()
    test_results["error_handling"] = test_error_handling()
    test_results["performance"] = performance_test()
    test_results["metrics"] = test_metrics_endpoint()
    
    # Summary
    print_header("Test Summary")
    
    passed_tests = sum(test_results.values())
    total_tests = len(test_results)
    
    for test_name, result in test_results.items():
        status = "PASS" if result else "FAIL"
        symbol = "✅" if result else "❌"
        print(f"{symbol} {test_name.replace('_', ' ').title()}: {status}")
    
    print(f"\n📊 Overall Results: {passed_tests}/{total_tests} tests passed")
    
    if passed_tests == total_tests:
        print_success("All tests passed! 🎉")
        print_info("The ML inference service is working correctly.")
    else:
        print_error(f"{total_tests - passed_tests} tests failed.")
        print_info("Please check the service configuration.")
    
    return passed_tests == total_tests

if __name__ == "__main__":
    try:
        success = main()
        exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⏹️  Demo interrupted by user")
        exit(1)
    except Exception as e:
        print(f"\n❌ Demo failed with error: {e}")
        exit(1)