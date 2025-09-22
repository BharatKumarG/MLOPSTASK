#!/usr/bin/env python3
"""
ML Model Training Script with Optional MLflow Tracking
Trains a Random Forest classifier on the Iris dataset
"""

import os
import pandas as pd
import numpy as np
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.preprocessing import StandardScaler
import pickle
import json

# Try to import MLflow, fallback to basic logging if not available
try:
    import mlflow
    import mlflow.sklearn
    MLFLOW_AVAILABLE = True
except ImportError:
    print("MLflow not available. Using basic model persistence.")
    MLFLOW_AVAILABLE = False

def setup_mlflow():
    """Setup MLflow tracking"""
    if not MLFLOW_AVAILABLE:
        return None
        
    try:
        # Set MLflow tracking URI using relative path
        # This works better in CI/CD environments
        mlflow.set_tracking_uri("./mlruns")
        
        # Ensure the mlruns directory exists
        os.makedirs("./mlruns", exist_ok=True)
        
        # Set or create experiment
        experiment_name = "iris-classification"
        try:
            experiment_id = mlflow.create_experiment(experiment_name)
        except mlflow.exceptions.MlflowException:
            experiment = mlflow.get_experiment_by_name(experiment_name)
            experiment_id = experiment.experiment_id if experiment else None
        
        mlflow.set_experiment(experiment_name)
        return experiment_id
        
    except Exception as e:
        print(f"Warning: MLflow setup failed: {e}")
        print("Continuing without MLflow logging...")
        return None


def load_and_prepare_data():
    """Load and prepare the Iris dataset"""
    # Load Iris dataset
    iris = load_iris()
    X = pd.DataFrame(iris.data, columns=iris.feature_names)
    y = pd.Series(iris.target, name='target')
    
    # Map target names for better interpretability
    target_names = {0: 'setosa', 1: 'versicolor', 2: 'virginica'}
    y_named = y.map(target_names)
    
    print("Dataset Info:")
    print(f"Features shape: {X.shape}")
    print(f"Target classes: {list(target_names.values())}")
    print(f"Feature names: {list(X.columns)}")
    
    return X, y, y_named, iris.target_names

def train_model(X_train, X_test, y_train, y_test, hyperparams):
    """Train Random Forest model with given hyperparameters"""
    
    # Initialize model
    model = RandomForestClassifier(
        n_estimators=hyperparams['n_estimators'],
        max_depth=hyperparams['max_depth'],
        random_state=hyperparams['random_state']
    )
    
    # Train model
    model.fit(X_train, y_train)
    
    # Make predictions
    y_pred = model.predict(X_test)
    y_pred_proba = model.predict_proba(X_test)
    
    # Calculate metrics
    accuracy = accuracy_score(y_test, y_pred)
    
    return model, y_pred, y_pred_proba, accuracy

def log_model_artifacts(model, X_test, y_test, y_pred, accuracy, feature_names, target_names):
    """Log model and artifacts to MLflow"""
    
    if MLFLOW_AVAILABLE:
        try:
            # Log model
            mlflow.sklearn.log_model(
                sk_model=model,
                artifact_path="model",
                registered_model_name="iris-classifier",
                input_example=X_test.iloc[:5],
                signature=mlflow.models.infer_signature(X_test, y_pred)
            )
        except Exception as e:
            print(f"Warning: Failed to log model to MLflow: {e}")
    
    # Always save model locally
    with open('model.pkl', 'wb') as f:
        pickle.dump(model, f)
    
    # Log feature importance
    feature_importance = pd.DataFrame({
        'feature': feature_names,
        'importance': model.feature_importances_
    }).sort_values('importance', ascending=False)
    
    feature_importance.to_csv('feature_importance.csv', index=False)
    if MLFLOW_AVAILABLE:
        try:
            mlflow.log_artifact('feature_importance.csv')
        except Exception as e:
            print(f"Warning: Failed to log feature importance to MLflow: {e}")
    
    # Log classification report
    from sklearn.metrics import classification_report
    report = classification_report(y_test, y_pred, target_names=target_names, output_dict=True)
    
    # Save and log classification report
    with open('classification_report.json', 'w') as f:
        json.dump(report, f, indent=2)
    if MLFLOW_AVAILABLE:
        try:
            mlflow.log_artifact('classification_report.json')
        except Exception as e:
            print(f"Warning: Failed to log classification report to MLflow: {e}")
    
    # Log confusion matrix
    from sklearn.metrics import confusion_matrix
    cm = confusion_matrix(y_test, y_pred)
    cm_df = pd.DataFrame(cm, index=target_names, columns=target_names)
    cm_df.to_csv('confusion_matrix.csv')
    if MLFLOW_AVAILABLE:
        try:
            mlflow.log_artifact('confusion_matrix.csv')
        except Exception as e:
            print(f"Warning: Failed to log confusion matrix to MLflow: {e}")
    
    print(f"Model logged with accuracy: {accuracy:.4f}")
    print("Feature Importance:")
    print(feature_importance)

def main():
    """Main training pipeline"""
    print("Starting ML model training with MLflow tracking...")
    
    # Setup MLflow
    experiment_id = setup_mlflow()
    
    # Load and prepare data
    X, y, y_named, target_names = load_and_prepare_data()
    
    # Split data
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    
    # Scale features
    scaler = StandardScaler()
    X_train_scaled = pd.DataFrame(
        scaler.fit_transform(X_train), 
        columns=X.columns,
        index=X_train.index
    )
    X_test_scaled = pd.DataFrame(
        scaler.transform(X_test), 
        columns=X.columns,
        index=X_test.index
    )
    
    # Define hyperparameters to test
    hyperparams_list = [
        {'n_estimators': 50, 'max_depth': 5, 'random_state': 42},
        {'n_estimators': 100, 'max_depth': 10, 'random_state': 42},
        {'n_estimators': 150, 'max_depth': None, 'random_state': 42}
    ]
    
    best_accuracy = 0
    best_run_id = None
    
    # Train models with different hyperparameters
    for i, hyperparams in enumerate(hyperparams_list):
        # Check if MLflow is available and setup was successful
        mlflow_enabled = MLFLOW_AVAILABLE and experiment_id is not None
        
        if mlflow_enabled:
            with mlflow.start_run(run_name=f"iris-rf-run-{i+1}") as run:
                print(f"\nTraining model {i+1}/3 with hyperparams: {hyperparams}")
                
                # Log hyperparameters
                mlflow.log_params(hyperparams)
                mlflow.log_param("test_size", 0.2)
                mlflow.log_param("scaling", "StandardScaler")
                
                # Train model
                model, y_pred, y_pred_proba, accuracy = train_model(
                    X_train_scaled, X_test_scaled, y_train, y_test, hyperparams
                )
                
                # Log metrics
                mlflow.log_metric("accuracy", accuracy)
                mlflow.log_metric("train_size", len(X_train))
                mlflow.log_metric("test_size", len(X_test))
                
                # Log model and artifacts
                log_model_artifacts(model, X_test_scaled, y_test, y_pred, accuracy, X.columns, target_names)
                
                # Track best model
                if accuracy > best_accuracy:
                    best_accuracy = accuracy
                    best_run_id = run.info.run_id
                
                print(f"Run {i+1} completed with accuracy: {accuracy:.4f}")
        else:
            print(f"\nTraining model {i+1}/3 with hyperparams: {hyperparams}")
            
            # Train model
            model, y_pred, y_pred_proba, accuracy = train_model(
                X_train_scaled, X_test_scaled, y_train, y_test, hyperparams
            )
            
            # Log model and artifacts
            log_model_artifacts(model, X_test_scaled, y_test, y_pred, accuracy, X.columns, target_names)
            
            # Track best model
            if accuracy > best_accuracy:
                best_accuracy = accuracy
                best_run_id = f"run-{i+1}"
                # Save best model
                with open('best_model.pkl', 'wb') as f:
                    pickle.dump(model, f)
            
            print(f"Run {i+1} completed with accuracy: {accuracy:.4f}")
    
    print(f"\nTraining completed!")
    print(f"Best model accuracy: {best_accuracy:.4f}")
    print(f"Best run ID: {best_run_id}")
    
    # Check if MLflow was successfully enabled
    mlflow_enabled = MLFLOW_AVAILABLE and experiment_id is not None
    
    if mlflow_enabled:
        print(f"MLflow UI: mlflow ui")
        print(f"Models logged to: ./mlruns")
    else:
        print(f"Best model saved to: best_model.pkl")
        print(f"Model artifacts saved locally")
        if not MLFLOW_AVAILABLE:
            print(f"Note: MLflow not available")
        else:
            print(f"Note: MLflow logging disabled due to permission issues")
    
    # Clean up temporary files
    import os
    for file in ['feature_importance.csv', 'classification_report.json', 'confusion_matrix.csv']:
        if os.path.exists(file):
            os.remove(file)

if __name__ == "__main__":
    main()