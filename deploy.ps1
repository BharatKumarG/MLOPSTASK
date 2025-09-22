# deploy.ps1 - MLOps Deployment Automation Script for Windows
# This script automates the complete deployment of the ML inference service

param(
    [switch]$SkipTests,
    [switch]$SkipModelTraining,
    [switch]$Help
)

# Configuration
$APP_NAME = "ml-inference-service"
$DOCKER_IMAGE = "$APP_NAME:latest"
$K8S_NAMESPACE = "default"
$HEALTH_CHECK_TIMEOUT = 300  # 5 minutes
$API_PORT = 5000

# Logging functions
function Write-Log {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message" -ForegroundColor Green
}

function Write-Error-Log {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Warning-Log {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Info-Log {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

# Show help
if ($Help) {
    Write-Host "Usage: .\deploy.ps1 [options]"
    Write-Host "Options:"
    Write-Host "  -SkipTests            Skip Docker and API tests"
    Write-Host "  -SkipModelTraining    Skip model training step"
    Write-Host "  -Help                 Show this help message"
    exit 0
}

# Check prerequisites
function Check-Prerequisites {
    Write-Log "Checking prerequisites..."
    
    $missingTools = @()
    
    if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
        $missingTools += "docker"
    }
    
    if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) {
        $missingTools += "kubectl"
    }
    
    if (!(Get-Command python -ErrorAction SilentlyContinue)) {
        $missingTools += "python"
    }
    
    if ($missingTools.Count -gt 0) {
        Write-Error-Log "Missing required tools: $($missingTools -join ', ')"
        Write-Error-Log "Please install these tools before running the deployment script."
        exit 1
    }
    
    Write-Log "All prerequisites satisfied"
}

# Train the ML model
function Train-Model {
    Write-Log "Training ML model..."
    
    if (Test-Path "train_model.py") {
        $result = python train_model.py
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Model training completed successfully"
        } else {
            Write-Error-Log "Model training failed"
            exit 1
        }
    } else {
        Write-Error-Log "train_model.py not found"
        exit 1
    }
}

# Build Docker image
function Build-DockerImage {
    Write-Log "Building Docker image: $DOCKER_IMAGE"
    
    if (!(Test-Path "Dockerfile")) {
        Write-Error-Log "Dockerfile not found"
        exit 1
    }
    
    $result = docker build -t $DOCKER_IMAGE .
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Docker image built successfully"
        docker images $DOCKER_IMAGE
    } else {
        Write-Error-Log "Docker build failed"
        exit 1
    }
}

# Test Docker image locally
function Test-DockerImage {
    Write-Log "Testing Docker image locally..."
    
    # Stop any existing container
    docker stop $APP_NAME 2>$null
    docker rm $APP_NAME 2>$null
    
    # Run container in background
    $result = docker run -d --name $APP_NAME -p "${API_PORT}:5000" $DOCKER_IMAGE
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Docker container started successfully"
        
        # Wait for service to be ready
        $retries = 30
        $healthPassed = $false
        
        while ($retries -gt 0) {
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:$API_PORT/health" -UseBasicParsing -TimeoutSec 5
                if ($response.StatusCode -eq 200) {
                    Write-Log "Health check passed"
                    $healthPassed = $true
                    break
                }
            } catch {
                # Ignore errors and retry
            }
            $retries--
            Start-Sleep 2
        }
        
        if (-not $healthPassed) {
            Write-Error-Log "Health check failed after 60 seconds"
            docker logs $APP_NAME
            docker stop $APP_NAME
            exit 1
        }
        
        # Test prediction endpoint
        try {
            $body = @{
                features = @(5.1, 3.5, 1.4, 0.2)
            } | ConvertTo-Json
            
            $response = Invoke-WebRequest -Uri "http://localhost:$API_PORT/predict" -Method POST -Body $body -ContentType "application/json" -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-Log "Prediction endpoint test passed"
            } else {
                throw "Unexpected response code"
            }
        } catch {
            Write-Error-Log "Prediction endpoint test failed"
            docker logs $APP_NAME
            docker stop $APP_NAME
            exit 1
        }
        
        # Stop test container
        docker stop $APP_NAME
        docker rm $APP_NAME
        Write-Log "Docker image tests completed successfully"
    } else {
        Write-Error-Log "Failed to start Docker container"
        exit 1
    }
}

# Main deployment function
function Main {
    Write-Log "Starting MLOps deployment pipeline..."
    
    Check-Prerequisites
    
    if (-not $SkipModelTraining) {
        Train-Model
    } else {
        Write-Warning-Log "Skipping model training"
    }
    
    Build-DockerImage
    
    if (-not $SkipTests) {
        Test-DockerImage
    } else {
        Write-Warning-Log "Skipping Docker tests"
    }
    
    Write-Log "Deployment completed successfully! 🚀"
    Write-Info-Log "Note: Kubernetes deployment requires kubectl configuration."
    Write-Info-Log "Use the bash version (deploy.sh) for full Kubernetes deployment on Linux/WSL."
}

# Run main function
Main