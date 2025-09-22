#!/usr/bin/env python3
"""
Test suite for ML Inference API
"""

import pytest
import json
import numpy as np
import tempfile
import os
from unittest.mock import patch, MagicMock
import sys
import pickle
from sklearn.ensemble import RandomForestClassifier
from sklearn.datasets import load_iris

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import app

@pytest.fixture
def client():
    """Create test client"""
    # Create a temporary model file for testing
    iris = load_iris()
    model = RandomForestClassifier(n_estimators=10, random_state=42)
    model.fit(iris.data, iris.target)
    
    with tempfile.NamedTemporaryFile(mode='wb', delete=False, suffix='.pkl') as f:
        pickle.dump(model, f)
        model_file = f.name
    
    # Mock the model loading
    with patch('app.load_model_from_mlflow') as mock_load:
        app.model = model
        app.model_info = {"source": "test", "file": "test_model.pkl"}
        app.model_version = "test"
        mock_load.return_value = True
        
        app.app.config['TESTING'] = True
        with app.app.test_client() as client:
            yield client
    
    # Cleanup
    try:
        os.unlink(model_file)
    except:
        pass

class TestHealthEndpoint:
    """Test health check endpoint"""
    
    def test_health_check_success(self, client):
        """Test successful health check"""
        response = client.get('/health')
        assert response.status_code == 200
        
        data = response.get_json()
        assert data['status'] == 'healthy'
        assert data['model_loaded'] is True
        assert 'timestamp' in data
        assert 'version' in data

    def test_health_check_with_no_model(self, client):
        """Test health check when model is not loaded"""
        with patch('app.model', None):
            response = client.get('/health')
            assert response.status_code == 503
            
            data = response.get_json()
            assert data['status'] == 'unhealthy'
            assert 'error' in data

class TestPredictionEndpoint:
    """Test prediction endpoint"""
    
    def test_prediction_success(self, client):
        """Test successful prediction"""
        data = {
            "features": [5.1, 3.5, 1.4, 0.2]  # Typical setosa
        }
        
        response = client.post('/predict', 
                             data=json.dumps(data),
                             content_type='application/json')
        
        assert response.status_code == 200
        
        result = response.get_json()
        assert 'prediction' in result
        assert 'probabilities' in result
        assert 'input_features' in result
        assert 'model_info' in result
        assert 'timestamp' in result
        
        # Check prediction structure
        pred = result['prediction']
        assert 'class_id' in pred
        assert 'class_name' in pred
        assert 'confidence' in pred
        
        # Check probabilities
        probs = result['probabilities']
        assert len(probs) == 3  # 3 classes
        assert all(isinstance(v, float) for v in probs.values())
        assert abs(sum(probs.values()) - 1.0) < 1e-6  # Should sum to 1

    def test_prediction_missing_features(self, client):
        """Test prediction with missing features field"""
        data = {"wrong_field": [5.1, 3.5, 1.4, 0.2]}
        
        response = client.post('/predict', 
                             data=json.dumps(data),
                             content_type='application/json')
        
        assert response.status_code == 400
        data = response.get_json()
        assert 'error' in data
        assert 'features' in data['error']

    def test_prediction_wrong_feature_count(self, client):
        """Test prediction with wrong number of features"""
        data = {"features": [5.1, 3.5, 1.4]}  # Missing one feature
        
        response = client.post('/predict', 
                             data=json.dumps(data),
                             content_type='application/json')
        
        assert response.status_code == 400
        data = response.get_json()
        assert 'error' in data

    def test_prediction_non_numeric_features(self, client):
        """Test prediction with non-numeric features"""
        data = {"features": ["a", "b", "c", "d"]}
        
        response = client.post('/predict', 
                             data=json.dumps(data),
                             content_type='application/json')
        
        assert response.status_code == 400
        data = response.get_json()
        assert 'error' in data

    def test_prediction_no_json(self, client):
        """Test prediction without JSON data"""
        response = client.post('/predict')
        assert response.status_code == 400
        data = response.get_json()
        assert 'error' in data
        assert 'JSON' in data['error']

    def test_prediction_no_model(self, client):
        """Test prediction when model is not loaded"""
        with patch('app.model', None):
            data = {"features": [5.1, 3.5, 1.4, 0.2]}
            
            response = client.post('/predict', 
                                 data=json.dumps(data),
                                 content_type='application/json')
            
            assert response.status_code == 503
            data = response.get_json()
            assert 'error' in data

class TestModelInfoEndpoint:
    """Test model info endpoint"""
    
    def test_model_info_success(self, client):
        """Test successful model info retrieval"""
        response = client.get('/model/info')
        assert response.status_code == 200
        
        data = response.get_json()
        assert 'model_info' in data
        assert 'feature_names' in data
        assert 'target_names' in data
        assert 'model_type' in data
        assert len(data['feature_names']) == 4
        assert len(data['target_names']) == 3

    def test_model_info_no_model(self, client):
        """Test model info when model is not loaded"""
        with patch('app.model', None):
            response = client.get('/model/info')
            assert response.status_code == 503

class TestMetricsEndpoint:
    """Test metrics endpoint"""
    
    def test_metrics_endpoint(self, client):
        """Test metrics endpoint"""
        response = client.get('/metrics')
        # Should work whether Prometheus is available or not
        assert response.status_code in [200, 503]

class TestErrorHandling:
    """Test error handling"""
    
    def test_404_error(self, client):
        """Test 404 error handling"""
        response = client.get('/nonexistent')
        assert response.status_code == 404
        
        data = response.get_json()
        assert 'error' in data
        assert 'available_endpoints' in data

class TestIntegration:
    """Integration tests"""
    
    def test_full_prediction_workflow(self, client):
        """Test complete prediction workflow"""
        # Check health
        health_response = client.get('/health')
        assert health_response.status_code == 200
        
        # Get model info
        info_response = client.get('/model/info')
        assert info_response.status_code == 200
        
        # Make prediction
        test_cases = [
            [5.1, 3.5, 1.4, 0.2],  # Setosa
            [7.0, 3.2, 4.7, 1.4],  # Versicolor
            [6.3, 3.3, 6.0, 2.5]   # Virginica
        ]
        
        for features in test_cases:
            data = {"features": features}
            response = client.post('/predict', 
                                 data=json.dumps(data),
                                 content_type='application/json')
            
            assert response.status_code == 200
            result = response.get_json()
            
            # Verify prediction is valid
            assert result['prediction']['class_id'] in [0, 1, 2]
            assert result['prediction']['class_name'] in ['setosa', 'versicolor', 'virginica']
            assert 0 <= result['prediction']['confidence'] <= 1

def test_model_training():
    """Test model training script"""
    # This would be more comprehensive in a real test
    import train_model
    
    # Test basic functionality
    X, y, y_named, target_names = train_model.load_and_prepare_data()
    assert X.shape[0] == 150
    assert len(target_names) == 3
    
    # Test model training
    from sklearn.model_selection import train_test_split
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    hyperparams = {'n_estimators': 10, 'max_depth': 5, 'random_state': 42}
    model, y_pred, y_pred_proba, accuracy = train_model.train_model(X_train, X_test, y_train, y_test, hyperparams)
    
    assert accuracy > 0.8  # Should have reasonable accuracy
    assert len(y_pred) == len(y_test)
    assert y_pred_proba.shape == (len(y_test), 3)

if __name__ == '__main__':
    pytest.main([__file__, '-v'])