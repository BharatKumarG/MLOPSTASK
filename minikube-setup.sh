#!/bin/bash

echo "============================================"
echo "       MLOps Minikube Setup Script"
echo "============================================"
echo

check_prerequisites() {
    echo "=== Checking Prerequisites ==="
    echo

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo "[ERROR] Docker is not installed"
        echo "Please install Docker from: https://docs.docker.com/get-docker/"
        exit 1
    fi
    echo "[OK] Docker is installed"

    # Check if Minikube is installed
    if ! command -v minikube &> /dev/null; then
        echo "[ERROR] Minikube is not installed"
        echo
        echo "To install Minikube:"
        echo "Linux: curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64"
        echo "macOS: brew install minikube"
        echo "Or visit: https://minikube.sigs.k8s.io/docs/start/"
        exit 1
    fi
    echo "[OK] Minikube is installed"

    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        echo "[ERROR] kubectl is not installed"
        echo
        echo "To install kubectl:"
        echo "Linux: snap install kubectl --classic"
        echo "macOS: brew install kubectl"
        echo "Or visit: https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi
    echo "[OK] kubectl is installed"
    echo
}

show_menu() {
    echo "=== Choose deployment option ==="
    echo
    echo "1. Full setup (Start Minikube + Build + Deploy)"
    echo "2. Start/Configure Minikube only"
    echo "3. Build Docker image only"
    echo "4. Deploy to existing Minikube"
    echo "5. Check Minikube status"
    echo "6. Access services (get URLs)"
    echo "7. View logs"
    echo "8. Clean up (delete deployment)"
    echo "9. Stop Minikube"
    echo "0. Exit"
    echo
}

setup_minikube() {
    echo
    echo "=== Setting up Minikube ==="
    echo

    # Check if Minikube is already running
    if minikube status &> /dev/null; then
        echo "[INFO] Minikube is already running"
    else
        echo "[INFO] Starting Minikube with Docker driver..."
        minikube start --driver=docker --cpus=4 --memory=4096 --disk-size=20g
        if [ $? -ne 0 ]; then
            echo "[ERROR] Failed to start Minikube"
            return 1
        fi
    fi

    echo "[INFO] Enabling required addons..."
    minikube addons enable ingress
    minikube addons enable metrics-server
    minikube addons enable dashboard

    echo "[INFO] Configuring Docker environment for Minikube..."
    eval $(minikube docker-env)

    echo "[INFO] Minikube setup completed!"
    echo
    minikube status
    return 0
}

build_image() {
    echo
    echo "=== Building Docker Image ==="
    echo

    echo "[INFO] Setting Docker environment to use Minikube's Docker daemon..."
    eval $(minikube docker-env)

    echo "[INFO] Training model..."
    python train_model.py
    if [ $? -ne 0 ]; then
        echo "[ERROR] Model training failed"
        return 1
    fi

    echo "[INFO] Building Docker image..."
    docker build -t ml-inference-service:latest .
    if [ $? -ne 0 ]; then
        echo "[ERROR] Docker build failed"
        return 1
    fi

    echo "[INFO] Verifying image..."
    docker images | grep ml-inference-service

    echo "[INFO] Docker image built successfully!"
    return 0
}

deploy_app() {
    echo
    echo "=== Deploying to Minikube ==="
    echo

    echo "[INFO] Applying Kubernetes manifests..."
    kubectl apply -f k8s/minikube-deployment.yaml
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to apply deployment"
        return 1
    fi

    echo "[INFO] Waiting for deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/ml-inference-service
    if [ $? -ne 0 ]; then
        echo "[ERROR] Deployment failed to become ready"
        return 1
    fi

    echo "[INFO] Deployment completed successfully!"
    echo
    kubectl get pods -l app=ml-inference-service
    kubectl get services
    return 0
}

check_status() {
    echo
    echo "=== Minikube Status ==="
    echo
    minikube status
    echo
    echo "=== Kubernetes Resources ==="
    kubectl get all
    echo
    echo "=== Pod Details ==="
    kubectl get pods -l app=ml-inference-service -o wide
}

access_services() {
    echo
    echo "=== Service Access Information ==="
    echo

    echo "[INFO] Getting service URLs..."
    SERVICE_URL=$(minikube service ml-inference-service --url)

    if [ ! -z "$SERVICE_URL" ]; then
        echo
        echo "=== Your ML API is accessible at: ==="
        echo "$SERVICE_URL"
        echo
        echo "=== Available endpoints: ==="
        echo "Health Check: $SERVICE_URL/health"
        echo "Model Info:   $SERVICE_URL/model/info"
        echo "Predictions:  $SERVICE_URL/predict (POST)"
        echo "Metrics:      $SERVICE_URL/metrics"
        echo
        
        echo "Testing health endpoint..."
        curl -s "$SERVICE_URL/health"
        echo
        echo
        
        echo "[INFO] To access the Kubernetes dashboard:"
        echo "Run: minikube dashboard"
        echo
    else
        echo "[ERROR] Could not get service URL"
        echo "[INFO] You can manually check with: minikube service ml-inference-service --url"
    fi
}

view_logs() {
    echo
    echo "=== Application Logs ==="
    echo
    echo "Choose log option:"
    echo "1. Current logs"
    echo "2. Follow logs (live)"
    echo "3. Previous logs"
    echo
    read -p "Enter choice (1-3): " log_choice

    case $log_choice in
        1)
            kubectl logs -l app=ml-inference-service --tail=50
            ;;
        2)
            echo "[INFO] Press Ctrl+C to stop following logs"
            kubectl logs -l app=ml-inference-service -f
            ;;
        3)
            kubectl logs -l app=ml-inference-service --previous --tail=50
            ;;
        *)
            echo "Invalid choice"
            ;;
    esac
}

cleanup() {
    echo
    echo "=== Cleaning up deployment ==="
    echo
    read -p "Are you sure you want to delete the deployment? (y/N): " confirm
    if [[ $confirm != [yY] ]]; then
        return 0
    fi

    echo "[INFO] Deleting Kubernetes resources..."
    kubectl delete -f k8s/minikube-deployment.yaml
    echo "[INFO] Cleanup completed!"
}

stop_minikube() {
    echo
    echo "=== Stopping Minikube ==="
    echo
    read -p "Are you sure you want to stop Minikube? (y/N): " confirm
    if [[ $confirm != [yY] ]]; then
        return 0
    fi

    echo "[INFO] Stopping Minikube..."
    minikube stop
    echo "[INFO] Minikube stopped!"
}

full_setup() {
    echo
    echo "=== Full MLOps Minikube Setup ==="
    echo
    setup_minikube || return 1
    build_image || return 1
    deploy_app || return 1
    access_services
}

# Main execution
check_prerequisites

while true; do
    show_menu
    read -p "Enter your choice (0-9): " choice
    
    case $choice in
        1) full_setup ;;
        2) setup_minikube ;;
        3) build_image ;;
        4) deploy_app ;;
        5) check_status ;;
        6) access_services ;;
        7) view_logs ;;
        8) cleanup ;;
        9) stop_minikube ;;
        0) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid option. Please try again."; sleep 1 ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
done