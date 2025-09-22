# Docker Container Monitoring Guide

## Current Status Analysis

Based on your output, your MLOps infrastructure is running successfully:

### ✅ Container Status
- **ml-inference-api**: Running and healthy
  - Responding to health checks (`GET /health HTTP/1.1" 200`)
  - Prometheus metrics being collected (`GET /metrics HTTP/1.1" 200`)
  - API is accessible and functional

- **mlflow-server**: Installing dependencies and initializing database
  - Successfully installed MLflow and dependencies
  - Database migrations completed successfully
  - This is normal startup behavior

- **grafana**: Ready and operational
  - Usage stats reporting enabled
  - Dashboard should be accessible

## Quick Commands for Monitoring

### 1. Check Container Status
```bash
# Show all running containers
docker ps

# Show container health
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### 2. View Container Logs
```bash
# ML API logs (live feed)
docker logs -f ml-inference-api

# MLflow server logs (live feed) 
docker logs -f mlflow-server

# All containers logs
docker-compose logs -f

# Last 50 lines from all containers
docker-compose logs --tail=50
```

### 3. Test Your Services

#### ML Inference API (Port 5000)
```bash
# Health check
curl http://localhost:5000/health

# Model info
curl http://localhost:5000/model/info

# Make a prediction
curl -X POST http://localhost:5000/predict \
  -H "Content-Type: application/json" \
  -d '{"features": [5.1, 3.5, 1.4, 0.2]}'

# Get metrics
curl http://localhost:5000/metrics
```

#### MLflow UI (Port 5001)
```bash
# Check if MLflow UI is accessible
curl -I http://localhost:5001
```
Open in browser: http://localhost:5001

#### Grafana Dashboard (Port 3000)
```bash
# Check Grafana status
curl -I http://localhost:3000
```
Open in browser: http://localhost:3000
- Default login: admin/admin

### 4. Resource Monitoring
```bash
# Real-time resource usage
docker stats

# One-time resource check
docker stats --no-stream
```

### 5. Container Management
```bash
# Stop specific container
docker stop ml-inference-api

# Restart specific container
docker restart ml-inference-api

# Stop all containers
docker-compose down

# Start all containers
docker-compose up -d

# Rebuild and restart
docker-compose up -d --build
```

## Understanding Your Current Output

### MLflow Server Initialization
The long installation output you see is **normal and expected**:

1. **Dependency Installation**: MLflow is installing required packages
2. **Database Migration**: Setting up PostgreSQL database schema
3. **Migration Steps**: Each `INFO [alembic.runtime.migration]` line shows database schema updates

This is a **one-time setup process** that happens on first run.

### ML Inference API
Your API is working perfectly:
- Health checks returning 200 OK
- Metrics being collected every 10 seconds
- Ready to serve predictions

## Automated Monitoring Scripts

I've created monitoring scripts for you:

### Windows (PowerShell/CMD)
```cmd
# Run the monitoring script
docker-monitor.bat
```

### Linux/Mac (Bash)
```bash
# Make executable and run
chmod +x docker-monitor.sh
./docker-monitor.sh
```

## Web Interfaces

Once fully started, access these URLs:

1. **ML API Documentation**: http://localhost:5000
2. **MLflow Tracking**: http://localhost:5001
3. **Grafana Dashboard**: http://localhost:3000

## Troubleshooting Commands

### If containers seem stuck:
```bash
# Check container processes
docker-compose ps

# Check detailed container info
docker inspect ml-inference-api

# Check container logs for errors
docker logs ml-inference-api | grep -i error
```

### If services are unreachable:
```bash
# Check port bindings
docker port ml-inference-api
docker port mlflow-server
docker port grafana

# Check network connectivity
docker network ls
docker network inspect mlopstask_default
```

## Performance Tips

1. **Monitor Resource Usage**: Use `docker stats` to ensure containers aren't using excessive resources
2. **Log Management**: Consider log rotation for long-running containers
3. **Health Checks**: Use the built-in health endpoints to monitor service status

## Next Steps

1. **Wait for MLflow to finish initialization** (the installation output will stop)
2. **Test the ML API** using the curl commands above
3. **Access the web interfaces** to explore your MLOps dashboard
4. **Set up Grafana dashboards** for monitoring your ML services

Your system is running correctly! The output you're seeing is normal startup behavior.