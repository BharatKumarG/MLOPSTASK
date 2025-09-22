@echo off
REM Docker Build Script for Windows
REM This script handles the Docker build process with proper error handling

echo 🐳 Building ML Inference API Docker Image...

REM Check if Docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker is not installed or not in PATH
    echo Please install Docker Desktop for Windows
    exit /b 1
)

REM Check if required files exist
echo 📋 Checking dependencies...

if not exist "requirements.txt" (
    echo ❌ requirements.txt not found!
    exit /b 1
)

if not exist "app.py" (
    echo ❌ app.py not found!
    exit /b 1
)

if not exist "train_model.py" (
    echo ❌ train_model.py not found!
    exit /b 1
)

echo ✅ All required files found

REM Clean up any existing models (optional)
echo 🧹 Cleaning up existing model files...
del /q *.pkl 2>nul
del /q *.csv 2>nul
del /q *.json 2>nul
echo ✅ Cleanup completed

REM Build Docker image
echo 🔨 Building Docker image...
docker build --no-cache -t ml-inference-api:latest .

if errorlevel 1 (
    echo ❌ Docker build failed
    exit /b 1
)

echo ✅ Docker image built successfully

REM Verify the image
echo 🔍 Verifying Docker image...
docker images ml-inference-api:latest

echo =================================================
echo 🎉 Build process completed successfully!
echo.
echo To run the container:
echo   docker run -p 5000:5000 ml-inference-api:latest
echo.
echo To run with docker-compose:
echo   docker-compose up ml-api
echo =================================================

pause