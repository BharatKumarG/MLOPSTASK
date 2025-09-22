@echo off
echo =============================================
echo    Minikube NodePort Access Helper
echo =============================================
echo.

:check_minikube
echo === Checking Minikube Status ===
minikube status >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Minikube is not running
    echo.
    echo To start Minikube:
    echo   minikube start --driver=docker --cpus=4 --memory=4096
    echo.
    pause
    exit /b 1
)
echo [OK] Minikube is running
echo.

:get_access_info
echo === Getting NodePort Access Information ===
echo.

:: Get Minikube IP
for /f "tokens=*" %%i in ('minikube ip 2^>nul') do set MINIKUBE_IP=%%i
if "%MINIKUBE_IP%"=="" (
    echo [ERROR] Could not get Minikube IP
    pause
    exit /b 1
)

echo Minikube IP: %MINIKUBE_IP%
echo NodePort: 30080
echo.

:check_service
echo === Checking Service Status ===
kubectl get service ml-inference-service >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] ML Inference Service not found
    echo.
    echo To deploy the service:
    echo   kubectl apply -f k8s/minikube-deployment.yaml
    echo.
    pause
    exit /b 1
)

echo [OK] Service is deployed
kubectl get service ml-inference-service
echo.

:show_urls
echo === Access URLs ===
echo.
set SERVICE_URL=http://%MINIKUBE_IP%:30080

echo ✅ Main API URL: %SERVICE_URL%
echo.
echo 📋 Available Endpoints:
echo   • Health Check:    %SERVICE_URL%/health
echo   • API Info:        %SERVICE_URL%/
echo   • Model Info:      %SERVICE_URL%/model/info
echo   • Make Prediction: %SERVICE_URL%/predict (POST)
echo   • Metrics:         %SERVICE_URL%/metrics
echo.

:menu
echo === Choose an action ===
echo.
echo 1. Test Health Endpoint
echo 2. Get Model Information
echo 3. Make a Sample Prediction
echo 4. View Metrics
echo 5. Open in Browser
echo 6. Check Pod Status
echo 7. View Pod Logs
echo 8. Port Forward (Alternative Access)
echo 9. Show Service Details
echo 0. Exit
echo.
set /p choice="Enter your choice (0-9): "

if "%choice%"=="1" goto test_health
if "%choice%"=="2" goto get_model_info
if "%choice%"=="3" goto make_prediction
if "%choice%"=="4" goto view_metrics
if "%choice%"=="5" goto open_browser
if "%choice%"=="6" goto check_pods
if "%choice%"=="7" goto view_logs
if "%choice%"=="8" goto port_forward
if "%choice%"=="9" goto service_details
if "%choice%"=="0" goto exit
goto menu

:test_health
echo.
echo === Testing Health Endpoint ===
echo GET %SERVICE_URL%/health
echo.
curl -s %SERVICE_URL%/health 2>nul || echo [ERROR] Could not reach health endpoint
echo.
echo.
pause
goto menu

:get_model_info
echo.
echo === Getting Model Information ===
echo GET %SERVICE_URL%/model/info
echo.
curl -s %SERVICE_URL%/model/info 2>nul || echo [ERROR] Could not reach model info endpoint
echo.
echo.
pause
goto menu

:make_prediction
echo.
echo === Making Sample Prediction ===
echo POST %SERVICE_URL%/predict
echo.
echo Sample request body: {"features": [5.1, 3.5, 1.4, 0.2]}
echo.
curl -X POST %SERVICE_URL%/predict -H "Content-Type: application/json" -d "{\"features\": [5.1, 3.5, 1.4, 0.2]}" 2>nul || echo [ERROR] Could not make prediction
echo.
echo.
pause
goto menu

:view_metrics
echo.
echo === Viewing Prometheus Metrics ===
echo GET %SERVICE_URL%/metrics
echo.
curl -s %SERVICE_URL%/metrics 2>nul || echo [ERROR] Could not reach metrics endpoint
echo.
echo.
pause
goto menu

:open_browser
echo.
echo === Opening in Browser ===
echo Opening %SERVICE_URL% in default browser...
start %SERVICE_URL%
echo.
pause
goto menu

:check_pods
echo.
echo === Checking Pod Status ===
kubectl get pods -l app=ml-inference-service -o wide
echo.
echo === Pod Details ===
kubectl describe pods -l app=ml-inference-service
echo.
pause
goto menu

:view_logs
echo.
echo === Pod Logs ===
echo.
echo Choose log option:
echo 1. Current logs
echo 2. Follow logs (live)
echo.
set /p log_choice="Enter choice (1-2): "

if "%log_choice%"=="1" (
    kubectl logs -l app=ml-inference-service --tail=50
) else if "%log_choice%"=="2" (
    echo [INFO] Press Ctrl+C to stop following logs
    kubectl logs -l app=ml-inference-service -f
)
echo.
pause
goto menu

:port_forward
echo.
echo === Port Forwarding (Alternative Access) ===
echo.
echo This will forward local port 8080 to the service
echo Access the service at: http://localhost:8080
echo.
echo Press Ctrl+C to stop port forwarding
kubectl port-forward service/ml-inference-service-clusterip 8080:80
echo.
pause
goto menu

:service_details
echo.
echo === Service Details ===
echo.
echo NodePort Service:
kubectl describe service ml-inference-service
echo.
echo ClusterIP Service:
kubectl describe service ml-inference-service-clusterip
echo.
pause
goto menu

:exit
echo.
echo === Summary ===
echo.
echo Your ML API is accessible at: %SERVICE_URL%
echo.
echo 🚀 Quick Test Commands:
echo   curl %SERVICE_URL%/health
echo   curl %SERVICE_URL%/model/info
echo.
echo Goodbye!
exit /b 0