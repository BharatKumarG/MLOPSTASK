#!/bin/bash
# Deploy.sh - MLOps Deployment Automation Script
# This script automates the complete deployment of the ML inference service

set -e  # Exit on any error

# Configuration
APP_NAME="ml-inference-service"
DOCKER_IMAGE="$APP_NAME:latest"
K8S_NAMESPACE="default"
HEALTH_CHECK_TIMEOUT=300  # 5 minutes
API_PORT=5000

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Check if required tools are installed
check_prerequisites() {
    log "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command -v docker &> /dev/null; then
        missing_tools+=("docker")
    fi
    
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    if ! command -v python &> /dev/null && ! command -v python3 &> /dev/null; then
        missing_tools+=("python")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        error "Missing required tools: ${missing_tools[*]}"
        error "Please install these tools before running the deployment script."
        exit 1
    fi
    
    log "All prerequisites satisfied"
}

# Train the ML model
train_model() {
    log "Training ML model..."
    
    if [ -f "train_model.py" ]; then
        if python train_model.py; then
            log "Model training completed successfully"
        else
            error "Model training failed"
            exit 1
        fi
    else
        error "train_model.py not found"
        exit 1
    fi
}

# Build Docker image
build_docker_image() {
    log "Building Docker image: $DOCKER_IMAGE"
    
    if [ ! -f "Dockerfile" ]; then
        error "Dockerfile not found"
        exit 1
    fi
    
    if docker build -t $DOCKER_IMAGE .; then
        log "Docker image built successfully"
    else
        error "Docker build failed"
        exit 1
    fi
    
    # Show image info
    docker images $DOCKER_IMAGE
}

# Test Docker image locally
test_docker_image() {
    log "Testing Docker image locally..."
    
    # Stop any existing container
    docker stop $APP_NAME 2>/dev/null || true
    docker rm $APP_NAME 2>/dev/null || true
    
    # Run container in background
    if docker run -d --name $APP_NAME -p $API_PORT:5000 $DOCKER_IMAGE; then
        log "Docker container started successfully"
        
        # Wait for service to be ready
        local retries=30
        while [ $retries -gt 0 ]; do
            if curl -f http://localhost:$API_PORT/health >/dev/null 2>&1; then
                log "Health check passed"
                break
            fi
            retries=$((retries - 1))
            sleep 2
        done
        
        if [ $retries -eq 0 ]; then
            error "Health check failed after 60 seconds"
            docker logs $APP_NAME
            docker stop $APP_NAME
            exit 1
        fi
        
        # Test prediction endpoint
        if curl -X POST http://localhost:$API_PORT/predict \
           -H \"Content-Type: application/json\" \
           -d '{\"features\": [5.1, 3.5, 1.4, 0.2]}' >/dev/null 2>&1; then
            log "Prediction endpoint test passed"
        else
            error "Prediction endpoint test failed"
            docker logs $APP_NAME
            docker stop $APP_NAME
            exit 1
        fi
        
        # Stop test container
        docker stop $APP_NAME
        docker rm $APP_NAME
        log "Docker image tests completed successfully"
    else
        error "Failed to start Docker container"
        exit 1
    fi
}

# Check Kubernetes cluster connectivity
check_k8s_cluster() {
    log "Checking Kubernetes cluster connectivity..."
    
    if kubectl cluster-info >/dev/null 2>&1; then
        log "Kubernetes cluster is accessible"
        kubectl get nodes
    else
        error "Cannot connect to Kubernetes cluster"
        error "Please ensure kubectl is configured correctly"
        exit 1
    fi
}

# Load Docker image to cluster (for local clusters like minikube)
load_image_to_cluster() {
    log "Loading Docker image to cluster..."
    
    # Check if we're using minikube
    if kubectl config current-context | grep -q minikube; then
        warning "Detected minikube cluster"
        if command -v minikube &> /dev/null; then
            # Load image to minikube
            if minikube image load $DOCKER_IMAGE; then
                log "Image loaded to minikube successfully"
            else
                error "Failed to load image to minikube"
                exit 1
            fi
        else
            warning "minikube command not found, skipping image load"
        fi
    else
        # For other clusters, we might need to push to a registry
        warning "Non-minikube cluster detected. You may need to push the image to a registry."
        info "Current image: $DOCKER_IMAGE"
    fi
}

# Apply Kubernetes manifests
apply_k8s_manifests() {
    log "Applying Kubernetes manifests..."
    
    if [ ! -d "k8s" ]; then
        error "k8s directory not found"
        exit 1
    fi
    
    # Update image in deployment
    if [ -f "k8s/deployment.yaml" ]; then
        # Create a temporary deployment file with the correct image
        sed \"s|image: ml-inference-service:latest|image: $DOCKER_IMAGE|g\" k8s/deployment.yaml > /tmp/deployment-temp.yaml
        
        if kubectl apply -f /tmp/deployment-temp.yaml; then
            log "Deployment applied successfully"
        else
            error "Failed to apply deployment"
            exit 1
        fi
        
        rm -f /tmp/deployment-temp.yaml
    else
        error "k8s/deployment.yaml not found"
        exit 1
    fi
    
    # Apply service
    if [ -f "k8s/service.yaml" ]; then
        if kubectl apply -f k8s/service.yaml; then
            log "Service applied successfully"
        else
            error "Failed to apply service"
            exit 1
        fi
    else
        error "k8s/service.yaml not found"
        exit 1
    fi
}

# Wait for pods to be ready
wait_for_pods() {
    log "Waiting for pods to be ready..."
    
    local timeout=$HEALTH_CHECK_TIMEOUT
    local start_time=$(date +%s)
    
    while true; do
        local ready_pods=$(kubectl get pods -l app=$APP_NAME -o jsonpath='{.items[*].status.conditions[?(@.type==\"Ready\")].status}' | grep -o True | wc -l)
        local total_pods=$(kubectl get pods -l app=$APP_NAME --no-headers | wc -l)
        
        if [ \"$ready_pods\" -eq \"$total_pods\" ] && [ \"$total_pods\" -gt 0 ]; then
            log \"All $total_pods pods are ready\"
            break
        fi
        
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ $elapsed -gt $timeout ]; then
            error \"Timeout waiting for pods to be ready\"
            kubectl get pods -l app=$APP_NAME
            kubectl describe pods -l app=$APP_NAME
            exit 1
        fi
        
        info \"Waiting for pods... ($ready_pods/$total_pods ready, ${elapsed}s elapsed)\"
        sleep 10
    done
}

# Test API endpoints through Kubernetes service
test_k8s_deployment() {
    log \"Testing Kubernetes deployment...\"
    
    # Get service endpoint
    local service_type=$(kubectl get service $APP_NAME -o jsonpath='{.spec.type}')
    local endpoint=\"\"
    
    if [ \"$service_type\" = \"NodePort\" ]; then
        local node_port=$(kubectl get service $APP_NAME -o jsonpath='{.spec.ports[0].nodePort}')
        if kubectl config current-context | grep -q minikube; then
            endpoint=\"$(minikube ip):$node_port\"
        else
            local node_ip=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type==\"ExternalIP\")].address}')
            if [ -z \"$node_ip\" ]; then
                node_ip=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type==\"InternalIP\")].address}')
            fi
            endpoint=\"$node_ip:$node_port\"
        fi
    elif [ \"$service_type\" = \"LoadBalancer\" ]; then
        # Wait for load balancer IP
        info \"Waiting for LoadBalancer IP...\"
        kubectl wait --for=condition=ready --timeout=300s service/$APP_NAME || true
        local lb_ip=$(kubectl get service $APP_NAME -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        local lb_port=$(kubectl get service $APP_NAME -o jsonpath='{.spec.ports[0].port}')
        endpoint=\"$lb_ip:$lb_port\"
    else
        # Port forward for testing
        warning \"Using port forwarding for testing...\"
        kubectl port-forward service/$APP_NAME $API_PORT:80 &
        local pf_pid=$!
        sleep 5
        endpoint=\"localhost:$API_PORT\"
    fi
    
    if [ -z \"$endpoint\" ]; then
        error \"Could not determine service endpoint\"
        exit 1
    fi
    
    log \"Testing endpoint: http://$endpoint\"
    
    # Test health endpoint
    local retries=30
    while [ $retries -gt 0 ]; do
        if curl -f http://$endpoint/health >/dev/null 2>&1; then
            log \"Health check passed\"
            break
        fi
        retries=$((retries - 1))
        sleep 10
    done
    
    if [ $retries -eq 0 ]; then
        error \"Health check failed\"
        exit 1
    fi
    
    # Test prediction endpoint
    if curl -X POST http://$endpoint/predict \
       -H \"Content-Type: application/json\" \
       -d '{\"features\": [5.1, 3.5, 1.4, 0.2]}' >/dev/null 2>&1; then
        log \"Prediction endpoint test passed\"
    else
        error \"Prediction endpoint test failed\"
        exit 1
    fi
    
    # Kill port-forward if it was used
    if [ ! -z \"${pf_pid:-}\" ]; then
        kill $pf_pid 2>/dev/null || true
    fi
    
    log \"Kubernetes deployment tests completed successfully\"
}

# Show deployment status
show_deployment_status() {
    log \"Deployment Status:\"
    echo \"\"
    
    info \"Pods:\"
    kubectl get pods -l app=$APP_NAME
    
    echo \"\"
    info \"Services:\"
    kubectl get services -l app=$APP_NAME
    
    echo \"\"
    info \"Deployments:\"
    kubectl get deployments -l app=$APP_NAME
    
    # Show access information
    local service_type=$(kubectl get service $APP_NAME -o jsonpath='{.spec.type}')
    echo \"\"
    info \"Access Information:\"
    
    if [ \"$service_type\" = \"NodePort\" ]; then
        local node_port=$(kubectl get service $APP_NAME -o jsonpath='{.spec.ports[0].nodePort}')
        if kubectl config current-context | grep -q minikube; then
            echo \"  API URL: http://$(minikube ip):$node_port\"
        else
            echo \"  NodePort: $node_port\"
            echo \"  Use: http://<node-ip>:$node_port\"
        fi
    elif [ \"$service_type\" = \"LoadBalancer\" ]; then
        local lb_ip=$(kubectl get service $APP_NAME -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        local lb_port=$(kubectl get service $APP_NAME -o jsonpath='{.spec.ports[0].port}')
        if [ ! -z \"$lb_ip\" ]; then
            echo \"  API URL: http://$lb_ip:$lb_port\"
        else
            echo \"  LoadBalancer IP: Pending\"
        fi
    fi
    
    echo \"\"
    info \"Example API calls:\"
    echo \"  Health: curl http://<endpoint>/health\"
    echo \"  Predict: curl -X POST http://<endpoint>/predict -H 'Content-Type: application/json' -d '{\\\"features\\\": [5.1, 3.5, 1.4, 0.2]}'\"
}

# Cleanup function
cleanup() {
    if [ ! -z \"${pf_pid:-}\" ]; then
        kill $pf_pid 2>/dev/null || true
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Main deployment function
main() {
    log \"Starting MLOps deployment pipeline...\"
    
    # Parse command line arguments
    local skip_tests=false
    local skip_model_training=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-tests)
                skip_tests=true
                shift
                ;;
            --skip-model-training)
                skip_model_training=true
                shift
                ;;
            -h|--help)
                echo \"Usage: $0 [options]\"
                echo \"Options:\"
                echo \"  --skip-tests           Skip Docker and API tests\"
                echo \"  --skip-model-training  Skip model training step\"
                echo \"  -h, --help            Show this help message\"
                exit 0
                ;;
            *)
                error \"Unknown option: $1\"
                exit 1
                ;;
        esac
    done
    
    # Execute deployment steps
    check_prerequisites
    
    if [ \"$skip_model_training\" = false ]; then
        train_model
    else
        warning \"Skipping model training\"
    fi
    
    build_docker_image
    
    if [ \"$skip_tests\" = false ]; then
        test_docker_image
    else
        warning \"Skipping Docker tests\"
    fi
    
    check_k8s_cluster
    load_image_to_cluster
    apply_k8s_manifests
    wait_for_pods
    
    if [ \"$skip_tests\" = false ]; then
        test_k8s_deployment
    else
        warning \"Skipping Kubernetes tests\"
    fi
    
    show_deployment_status
    
    log \"Deployment completed successfully! 🚀\"
}

# Run main function
main \"$@\"