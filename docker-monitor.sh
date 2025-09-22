#!/bin/bash

# MLOps Docker Container Monitoring Script
echo "MLOps Docker Container Monitoring Script"
echo "========================================"
echo

show_menu() {
    echo "Choose an option:"
    echo "1. Show all running containers"
    echo "2. Check ML API logs (live)"
    echo "3. Check MLflow server logs (live)"
    echo "4. Check Grafana logs (live)"
    echo "5. Check container status"
    echo "6. Test API endpoints"
    echo "7. Show container resource usage"
    echo "8. Stop all containers"
    echo "9. Exit"
    echo
}

check_containers() {
    echo
    echo "=== Running Containers ==="
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo
}

check_api_logs() {
    echo
    echo "=== ML Inference API Logs (Press Ctrl+C to stop) ==="
    docker logs -f ml-inference-api
}

check_mlflow_logs() {
    echo
    echo "=== MLflow Server Logs (Press Ctrl+C to stop) ==="
    docker logs -f mlflow-server
}

check_grafana_logs() {
    echo
    echo "=== Grafana Logs (Press Ctrl+C to stop) ==="
    docker logs -f grafana
}

check_status() {
    echo
    echo "=== Container Health Status ==="
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.State}}"
    echo
    echo "=== Container Resource Usage ==="
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
    echo
}

test_endpoints() {
    echo
    echo "=== Testing API Endpoints ==="
    echo
    echo "Testing ML API Health..."
    if command -v jq >/dev/null 2>&1; then
        curl -s http://localhost:5000/health | jq .
    else
        curl -s http://localhost:5000/health
        echo
        echo "(Install jq for better JSON formatting)"
    fi
    echo
    echo
    echo "Testing MLflow UI..."
    curl -s -o /dev/null -w "MLflow UI Status: %{http_code}\n" http://localhost:5001
    echo
    echo "Testing Grafana..."
    curl -s -o /dev/null -w "Grafana Status: %{http_code}\n" http://localhost:3000
    echo
}

show_stats() {
    echo
    echo "=== Real-time Container Stats (Press Ctrl+C to stop) ==="
    docker stats
}

stop_containers() {
    echo
    echo "=== Stopping all containers ==="
    docker-compose down
    echo "Containers stopped."
}

# Main menu loop
while true; do
    show_menu
    read -p "Enter your choice (1-9): " choice
    
    case $choice in
        1) check_containers; read -p "Press Enter to continue..." ;;
        2) check_api_logs ;;
        3) check_mlflow_logs ;;
        4) check_grafana_logs ;;
        5) check_status; read -p "Press Enter to continue..." ;;
        6) test_endpoints; read -p "Press Enter to continue..." ;;
        7) show_stats ;;
        8) stop_containers; read -p "Press Enter to continue..." ;;
        9) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid option. Please try again."; sleep 1 ;;
    esac
done