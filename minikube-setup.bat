@echo off
echo ============================================
echo       MLOps Minikube Setup Script
echo ============================================
echo.

:check_prerequisites
echo === Checking Prerequisites ===
echo.

:: Check if Docker is installed
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not installed or not in PATH
    echo Please install Docker Desktop from: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)
echo [OK] Docker is installed

:: Check if Minikube is installed
minikube version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Minikube is not installed
    echo.
    echo To install Minikube on Windows:
    echo 1. Download from: https://minikube.sigs.k8s.io/docs/start/
    echo 2. Or use Chocolatey: choco install minikube
    echo 3. Or use winget: winget install Kubernetes.minikube
    pause
    exit /b 1
)
echo [OK] Minikube is installed

:: Check if kubectl is installed
kubectl version --client >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] kubectl is not installed
    echo.
    echo To install kubectl on Windows:
    echo 1. Download from: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
    echo 2. Or use Chocolatey: choco install kubernetes-cli
    echo 3. Or use winget: winget install Kubernetes.kubectl
    pause
    exit /b 1
)
echo [OK] kubectl is installed
echo.

:menu
echo === Choose deployment option ===
echo.
echo 1. Full setup (Start Minikube + Build + Deploy)
echo 2. Start/Configure Minikube only
echo 3. Build Docker image only
echo 4. Deploy to existing Minikube
echo 5. Check Minikube status
echo 6. Access services (get URLs)
echo 7. View logs
echo 8. Clean up (delete deployment)
echo 9. Stop Minikube
echo 0. Exit
echo.
set /p choice="Enter your choice (0-9): "

if "%choice%"=="1" goto full_setup
if "%choice%"=="2" goto setup_minikube
if "%choice%"=="3" goto build_image
if "%choice%"=="4" goto deploy_app
if "%choice%"=="5" goto check_status
if "%choice%"=="6" goto access_services
if "%choice%"=="7" goto view_logs
if "%choice%"=="8" goto cleanup
if "%choice%"=="9" goto stop_minikube
if "%choice%"=="0" goto exit
goto menu

:full_setup
echo.
echo === Full MLOps Minikube Setup ===
echo.
call :setup_minikube
if %errorlevel% neq 0 goto menu
call :build_image
if %errorlevel% neq 0 goto menu
call :deploy_app
if %errorlevel% neq 0 goto menu
call :access_services
goto menu

:setup_minikube
echo.
echo === Setting up Minikube ===
echo.

:: Check if Minikube is already running
minikube status >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] Minikube is already running
) else (
    echo [INFO] Starting Minikube with Docker driver...
    minikube start --driver=docker --cpus=4 --memory=4096 --disk-size=20g
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to start Minikube
        exit /b 1
    )
)

echo [INFO] Enabling required addons...
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable dashboard

echo [INFO] Configuring Docker environment for Minikube...
@echo on
eval $(minikube docker-env)
@echo off

echo [INFO] Minikube setup completed!
echo.
minikube status
exit /b 0

:build_image
echo.
echo === Building Docker Image ===
echo.

echo [INFO] Setting Docker environment to use Minikube's Docker daemon...
@echo on
@REM Configure Docker to use Minikube's Docker daemon
for /f "tokens=*" %%i in ('minikube docker-env --shell cmd') do %%i
@echo off

echo [INFO] Training model...
python train_model.py
if %errorlevel% neq 0 (
    echo [ERROR] Model training failed
    exit /b 1
)

echo [INFO] Building Docker image...
docker build -t ml-inference-service:latest .
if %errorlevel% neq 0 (
    echo [ERROR] Docker build failed
    exit /b 1
)

echo [INFO] Verifying image...
docker images | findstr ml-inference-service

echo [INFO] Docker image built successfully!
exit /b 0

:deploy_app
echo.
echo === Deploying to Minikube ===
echo.

echo [INFO] Applying Kubernetes manifests...
kubectl apply -f k8s/minikube-deployment.yaml
if %errorlevel% neq 0 (
    echo [ERROR] Failed to apply deployment
    exit /b 1
)

echo [INFO] Waiting for deployment to be ready...
kubectl wait --for=condition=available --timeout=300s deployment/ml-inference-service
if %errorlevel% neq 0 (
    echo [ERROR] Deployment failed to become ready
    exit /b 1
)

echo [INFO] Deployment completed successfully!
echo.
kubectl get pods -l app=ml-inference-service
kubectl get services
exit /b 0

:check_status
echo.
echo === Minikube Status ===
echo.
minikube status
echo.
echo === Kubernetes Resources ===
kubectl get all
echo.
echo === Pod Details ===
kubectl get pods -l app=ml-inference-service -o wide
exit /b 0

:access_services
echo.
echo === Service Access Information ===
echo.

echo [INFO] Getting service URLs...
set SERVICE_URL=
for /f "tokens=*" %%i in ('minikube service ml-inference-service --url') do set SERVICE_URL=%%i

if defined SERVICE_URL (
    echo.
    echo === Your ML API is accessible at: ===
    echo %SERVICE_URL%
    echo.
    echo === Available endpoints: ===
    echo Health Check: %SERVICE_URL%/health
    echo Model Info:   %SERVICE_URL%/model/info
    echo Predictions:  %SERVICE_URL%/predict (POST)
    echo Metrics:      %SERVICE_URL%/metrics
    echo.
    
    echo Testing health endpoint...
    curl -s %SERVICE_URL%/health
    echo.
    echo.
    
    echo [INFO] To access the Kubernetes dashboard:
    echo Run: minikube dashboard
    echo.
) else (
    echo [ERROR] Could not get service URL
    echo [INFO] You can manually check with: minikube service ml-inference-service --url
)
exit /b 0

:view_logs
echo.
echo === Application Logs ===
echo.
echo Choose log option:
echo 1. Current logs
echo 2. Follow logs (live)
echo 3. Previous logs
echo.
set /p log_choice="Enter choice (1-3): "

if "%log_choice%"=="1" (
    kubectl logs -l app=ml-inference-service --tail=50
) else if "%log_choice%"=="2" (
    echo [INFO] Press Ctrl+C to stop following logs
    kubectl logs -l app=ml-inference-service -f
) else if "%log_choice%"=="3" (
    kubectl logs -l app=ml-inference-service --previous --tail=50
) else (
    echo Invalid choice
)
exit /b 0

:cleanup
echo.
echo === Cleaning up deployment ===
echo.
set /p confirm="Are you sure you want to delete the deployment? (y/N): "
if /i "%confirm%" neq "y" goto menu

echo [INFO] Deleting Kubernetes resources...
kubectl delete -f k8s/minikube-deployment.yaml
echo [INFO] Cleanup completed!
exit /b 0

:stop_minikube
echo.
echo === Stopping Minikube ===
echo.
set /p confirm="Are you sure you want to stop Minikube? (y/N): "
if /i "%confirm%" neq "y" goto menu

echo [INFO] Stopping Minikube...
minikube stop
echo [INFO] Minikube stopped!
exit /b 0

:exit
echo.
echo Goodbye!
exit /b 0