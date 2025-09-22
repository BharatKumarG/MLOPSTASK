@echo off
echo MLOps Docker Container Monitoring Script
echo ========================================
echo.

:menu
echo Choose an option:
echo 1. Show all running containers
echo 2. Check ML API logs (live)
echo 3. Check MLflow server logs (live)
echo 4. Check Grafana logs (live)
echo 5. Check container status
echo 6. Test API endpoints
echo 7. Show container resource usage
echo 8. Stop all containers
echo 9. Exit
echo.
set /p choice="Enter your choice (1-9): "

if "%choice%"=="1" goto containers
if "%choice%"=="2" goto api_logs
if "%choice%"=="3" goto mlflow_logs
if "%choice%"=="4" goto grafana_logs
if "%choice%"=="5" goto status
if "%choice%"=="6" goto test_api
if "%choice%"=="7" goto stats
if "%choice%"=="8" goto stop
if "%choice%"=="9" goto exit
goto menu

:containers
echo.
echo === Running Containers ===
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo.
pause
goto menu

:api_logs
echo.
echo === ML Inference API Logs (Press Ctrl+C to stop) ===
docker logs -f ml-inference-api
goto menu

:mlflow_logs
echo.
echo === MLflow Server Logs (Press Ctrl+C to stop) ===
docker logs -f mlflow-server
goto menu

:grafana_logs
echo.
echo === Grafana Logs (Press Ctrl+C to stop) ===
docker logs -f grafana
goto menu

:status
echo.
echo === Container Health Status ===
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.State}}"
echo.
echo === Container Resource Usage ===
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
echo.
pause
goto menu

:test_api
echo.
echo === Testing API Endpoints ===
echo.
echo Testing ML API Health...
curl -s http://localhost:5000/health | jq . 2>nul || echo "Install jq for better JSON formatting"
echo.
echo.
echo Testing MLflow UI...
curl -s -o nul -w "MLflow UI Status: %%{http_code}\n" http://localhost:5001
echo.
echo Testing Grafana...
curl -s -o nul -w "Grafana Status: %%{http_code}\n" http://localhost:3000
echo.
pause
goto menu

:stats
echo.
echo === Real-time Container Stats (Press Ctrl+C to stop) ===
docker stats
goto menu

:stop
echo.
echo === Stopping all containers ===
docker-compose down
echo Containers stopped.
pause
goto menu

:exit
echo Goodbye!
exit /b 0