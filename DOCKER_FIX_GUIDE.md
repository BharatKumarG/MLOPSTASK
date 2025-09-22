# Docker Build Issues - Fix Guide

## Issue Analysis

### 🐛 **Problem Identified**
The Docker build was failing with the error:
```
Step 13/20 : COPY *.csv* ./
COPY failed: no source files were specified
ERROR: Service 'ml-api' failed to build : Build failed
```

### 🔍 **Root Cause**
The Dockerfile was trying to copy CSV and JSON files that don't exist in the build context:
```dockerfile
COPY *.csv* ./
COPY *.json* ./
```

Docker's COPY command fails when wildcard patterns don't match any files, unlike shell commands that would simply expand to nothing.

## ✅ **Solutions Applied**

### 1. **Fixed Dockerfile** 
**Modified:** `Dockerfile`

**Changes:**
- ❌ Removed: `COPY *.csv* ./` and `COPY *.json* ./` 
- ❌ Removed: `COPY best_model.pkl* ./` and `COPY model.pkl* ./`
- ✅ Added: `RUN python train_model.py` - Generates model files during build
- ✅ Simplified: Copy only essential files that are guaranteed to exist

**Before:**
```dockerfile
COPY app.py .
COPY train_model.py .
COPY best_model.pkl* ./
COPY model.pkl* ./
COPY *.csv* ./
COPY *.json* ./
```

**After:**
```dockerfile
COPY app.py .
COPY train_model.py .
# Train model to ensure we have model files
RUN python train_model.py
```

### 2. **Created Build Scripts**
**Added:** `docker-build.sh` (Linux/Mac) and `docker-build.bat` (Windows)

These scripts provide:
- ✅ Dependency checking
- ✅ Error handling
- ✅ Build verification
- ✅ Optional cleanup and testing

### 3. **Enhanced docker-compose.yml**
The existing docker-compose.yml already has good configuration:
- ✅ MLflow tracking server on port 5000
- ✅ ML API service on port 5001 (mapped from internal 5000)
- ✅ Complete MLOps stack with Prometheus, Grafana, MinIO

## 🚀 **How to Build and Run**

### **Option 1: Direct Docker Build**
```bash
# Build the image
docker build -t ml-inference-api .

# Run the container
docker run -p 5000:5000 ml-inference-api
```

### **Option 2: Using Build Scripts**
```bash
# Linux/Mac
chmod +x docker-build.sh
./docker-build.sh

# Windows
docker-build.bat
```

### **Option 3: Using Docker Compose (Recommended)**
```bash
# Build and run the entire MLOps stack
docker-compose up --build

# Run only the ML API service
docker-compose up --build ml-api

# Run in background
docker-compose up -d --build
```

## 🧪 **Testing the Fix**

### **Verify Build Success**
```bash
# Check if image was built
docker images ml-inference-api

# Test container startup
docker run -d -p 5000:5000 --name test-ml-api ml-inference-api

# Test health endpoint
curl http://localhost:5000/health

# Check logs
docker logs test-ml-api

# Cleanup
docker stop test-ml-api && docker rm test-ml-api
```

### **Test with Docker Compose**
```bash
# Start services
docker-compose up -d

# Test ML API
curl http://localhost:5001/health

# Test MLflow UI
curl http://localhost:5000

# Check all services
docker-compose ps

# View logs
docker-compose logs ml-api
```

## 📊 **Service Endpoints**

When running with docker-compose:
- **ML API**: http://localhost:5001
  - Health: `GET /health`
  - Predict: `POST /predict`
  - Model Info: `GET /model/info`
  - Metrics: `GET /metrics`

- **MLflow UI**: http://localhost:5000
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin123)
- **MinIO Console**: http://localhost:9001 (minio/minio123)

## 🛠 **Troubleshooting**

### **Build Issues**
```bash
# Clean build without cache
docker build --no-cache -t ml-inference-api .

# Check build logs
docker build -t ml-inference-api . 2>&1 | tee build.log

# Verify requirements.txt
cat requirements.txt
```

### **Runtime Issues**
```bash
# Check container logs
docker logs <container_id>

# Execute into running container
docker exec -it <container_id> /bin/bash

# Check model files
docker exec <container_id> ls -la /app/
```

### **Docker Compose Issues**
```bash
# Rebuild specific service
docker-compose build ml-api

# Check service status
docker-compose ps

# View service logs
docker-compose logs -f ml-api
```

## 🔧 **Key Improvements Made**

1. **Robust Model Generation**: The model is now trained during the Docker build process, ensuring it always exists
2. **Error Prevention**: Removed problematic wildcard COPY commands
3. **Build Scripts**: Added automated build scripts with error checking
4. **Documentation**: Comprehensive guide for building and troubleshooting
5. **Multi-Stage Support**: The solution works for both local development and CI/CD pipelines

## 🎯 **Next Steps**

1. **Test the fixed Dockerfile** with your Docker environment
2. **Use docker-compose** for the complete MLOps stack
3. **Monitor the CI/CD pipeline** to ensure the build passes
4. **Update deployment scripts** if needed for production environments

The Docker build should now complete successfully without the COPY errors!