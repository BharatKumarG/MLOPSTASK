@echo off
echo ========================================
echo    ML Inference Project - Component Runner
echo ========================================
echo.
echo Select which component to run:
echo.
echo 1. Train ML Model
echo 2. Start API Service (Port 5000)
echo 3. Run API Tests
echo 4. Start Web Dashboard (Port 8080)
echo 5. Full Setup (API + Web Interface)
echo 6. Docker Build and Run
echo 7. View MLflow UI
echo 8. Exit
echo.
set /p choice="Enter your choice (1-8): "

if "%choice%"=="1" goto train
if "%choice%"=="2" goto api
if "%choice%"=="3" goto test
if "%choice%"=="4" goto web
if "%choice%"=="5" goto full
if "%choice%"=="6" goto docker
if "%choice%"=="7" goto mlflow
if "%choice%"=="8" goto exit
goto invalid

:train
echo.
echo 🤖 Training ML Model...
echo ========================================
python train_model.py
pause
goto menu

:api
echo.
echo 🚀 Starting API Service on port 5000...
echo ========================================
echo Press Ctrl+C to stop the service
python app.py
pause
goto menu

:test
echo.
echo 🧪 Running API Tests...
echo ========================================
python demo.py
pause
goto menu

:web
echo.
echo 🌐 Starting Web Dashboard on port 8080...
echo ========================================
echo Press Ctrl+C to stop the service
echo Open browser to: http://localhost:8080
python web_interface.py
pause
goto menu

:full
echo.
echo 🚀 Starting Full Setup...
echo ========================================
echo This will open multiple windows:
echo   - API Service (Port 5000)
echo   - Web Dashboard (Port 8080)
echo.
pause
start cmd /k "python app.py"
timeout /t 3 /nobreak
start cmd /k "python web_interface.py"
timeout /t 3 /nobreak
start "" "http://localhost:8080"
echo Services started! Check the new windows.
pause
goto menu

:docker
echo.
echo 🐳 Docker Build and Run...
echo ========================================
echo Building Docker image...
docker build -t ml-inference .
if %errorlevel% equ 0 (
    echo.
    echo Running Docker container...
    docker run -p 5000:5000 ml-inference
) else (
    echo Docker build failed!
)
pause
goto menu

:mlflow
echo.
echo 📊 Starting MLflow UI...
echo ========================================
echo MLflow UI will be available at: http://localhost:5000
start cmd /k "mlflow ui"
timeout /t 3 /nobreak
start "" "http://localhost:5000"
pause
goto menu

:invalid
echo.
echo ❌ Invalid choice! Please select 1-8.
pause
goto menu

:exit
echo.
echo 👋 Goodbye!
exit

:menu
cls
goto :start