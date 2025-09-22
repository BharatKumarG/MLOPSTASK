#!/bin/bash

# Docker Build Script for ML Inference API
# This script handles the Docker build process with proper error handling

set -e  # Exit on any error

echo "🐳 Building ML Inference API Docker Image..."

# Function to check if required files exist
check_dependencies() {
    echo "📋 Checking dependencies..."
    
    if [ ! -f "requirements.txt" ]; then
        echo "❌ requirements.txt not found!"
        exit 1
    fi
    
    if [ ! -f "app.py" ]; then
        echo "❌ app.py not found!"
        exit 1
    fi
    
    if [ ! -f "train_model.py" ]; then
        echo "❌ train_model.py not found!"
        exit 1
    fi
    
    echo "✅ All required files found"
}

# Function to clean up any existing models (optional)
cleanup_models() {
    echo "🧹 Cleaning up existing model files..."
    rm -f *.pkl *.csv *.json || true
    echo "✅ Cleanup completed"
}

# Function to build Docker image
build_image() {
    echo "🔨 Building Docker image..."
    
    # Build with build args for cache busting if needed
    docker build \
        --no-cache \
        -t ml-inference-api:latest \
        -t ml-inference-api:$(date +%Y%m%d-%H%M%S) \
        .
    
    echo "✅ Docker image built successfully"
}

# Function to verify the image
verify_image() {
    echo "🔍 Verifying Docker image..."
    
    # Check if image exists
    if docker images ml-inference-api:latest | grep -q ml-inference-api; then
        echo "✅ Image verification successful"
        
        # Show image details
        echo "📊 Image details:"
        docker images ml-inference-api:latest
    else
        echo "❌ Image verification failed"
        exit 1
    fi
}

# Function to test the container
test_container() {
    echo "🧪 Testing container startup..."
    
    # Start container in detached mode
    CONTAINER_ID=$(docker run -d -p 5000:5000 ml-inference-api:latest)
    
    # Wait for startup
    echo "⏳ Waiting for container to start..."
    sleep 10
    
    # Test health endpoint
    if curl -f http://localhost:5000/health &>/dev/null; then
        echo "✅ Container test successful"
    else
        echo "❌ Container test failed"
        docker logs $CONTAINER_ID
    fi
    
    # Cleanup test container
    docker stop $CONTAINER_ID &>/dev/null || true
    docker rm $CONTAINER_ID &>/dev/null || true
}

# Main execution
main() {
    echo "🚀 Starting ML Inference API Docker build process..."
    echo "================================================="
    
    check_dependencies
    cleanup_models
    build_image
    verify_image
    
    # Optional: Test the container (uncomment to enable)
    # test_container
    
    echo "================================================="
    echo "🎉 Build process completed successfully!"
    echo ""
    echo "To run the container:"
    echo "  docker run -p 5000:5000 ml-inference-api:latest"
    echo ""
    echo "To run with docker-compose:"
    echo "  docker-compose up ml-api"
}

# Run main function
main "$@"