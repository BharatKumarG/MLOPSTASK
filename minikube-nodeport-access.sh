#!/bin/bash

echo "============================================="
echo "    Minikube NodePort Access Helper"
echo "============================================="
echo

check_minikube() {
    echo "=== Checking Minikube Status ==="
    if ! minikube status &> /dev/null; then
        echo "[ERROR] Minikube is not running"
        echo
        echo "To start Minikube:"
        echo "  minikube start --driver=docker --cpus=4 --memory=4096"
        echo
        exit 1
    fi
    echo "[OK] Minikube is running"
    echo
}

get_access_info() {
    echo "=== Getting NodePort Access Information ==="
    echo

    # Get Minikube IP
    MINIKUBE_IP=$(minikube ip 2>/dev/null)
    if [ -z "$MINIKUBE_IP" ]; then
        echo "[ERROR] Could not get Minikube IP"
        exit 1
    fi

    echo "Minikube IP: $MINIKUBE_IP"
    echo "NodePort: 30080"
    echo

    SERVICE_URL="http://$MINIKUBE_IP:30080"
}

check_service() {
    echo "=== Checking Service Status ==="
    if ! kubectl get service ml-inference-service &> /dev/null; then
        echo "[ERROR] ML Inference Service not found"
        echo
        echo "To deploy the service:"
        echo "  kubectl apply -f k8s/minikube-deployment.yaml"
        echo
        exit 1
    fi

    echo "[OK] Service is deployed"
    kubectl get service ml-inference-service
    echo
}

show_urls() {
    echo "=== Access URLs ==="
    echo
    echo "✅ Main API URL: $SERVICE_URL"
    echo
    echo "📋 Available Endpoints:"
    echo "  • Health Check:    $SERVICE_URL/health"
    echo "  • API Info:        $SERVICE_URL/"
    echo "  • Model Info:      $SERVICE_URL/model/info"
    echo "  • Make Prediction: $SERVICE_URL/predict (POST)"
    echo "  • Metrics:         $SERVICE_URL/metrics"
    echo
}

show_menu() {
    echo "=== Choose an action ==="
    echo
    echo "1. Test Health Endpoint"
    echo "2. Get Model Information"
    echo "3. Make a Sample Prediction"
    echo "4. View Metrics"
    echo "5. Open in Browser"
    echo "6. Check Pod Status"
    echo "7. View Pod Logs"
    echo "8. Port Forward (Alternative Access)"
    echo "9. Show Service Details"
    echo "0. Exit"
    echo
}

test_health() {
    echo
    echo "=== Testing Health Endpoint ==="
    echo "GET $SERVICE_URL/health"
    echo
    if curl -s "$SERVICE_URL/health" 2>/dev/null; then
        echo
    else
        echo "[ERROR] Could not reach health endpoint"
    fi
    echo
}

get_model_info() {
    echo
    echo "=== Getting Model Information ==="
    echo "GET $SERVICE_URL/model/info"
    echo
    if curl -s "$SERVICE_URL/model/info" 2>/dev/null; then
        echo
    else
        echo "[ERROR] Could not reach model info endpoint"
    fi
    echo
}

make_prediction() {
    echo
    echo "=== Making Sample Prediction ==="
    echo "POST $SERVICE_URL/predict"
    echo
    echo "Sample request body: {\"features\": [5.1, 3.5, 1.4, 0.2]}"
    echo
    if curl -X POST "$SERVICE_URL/predict" \
        -H "Content-Type: application/json" \
        -d '{"features": [5.1, 3.5, 1.4, 0.2]}' 2>/dev/null; then
        echo
    else
        echo "[ERROR] Could not make prediction"
    fi
    echo
}

view_metrics() {
    echo
    echo "=== Viewing Prometheus Metrics ==="
    echo "GET $SERVICE_URL/metrics"
    echo
    if curl -s "$SERVICE_URL/metrics" 2>/dev/null; then
        echo
    else
        echo "[ERROR] Could not reach metrics endpoint"
    fi
    echo
}

open_browser() {
    echo
    echo "=== Opening in Browser ==="
    echo "Opening $SERVICE_URL in default browser..."
    
    case "$(uname -s)" in
        Darwin) open "$SERVICE_URL" ;;
        Linux) xdg-open "$SERVICE_URL" ;;
        CYGWIN*|MINGW*|MSYS*) start "$SERVICE_URL" ;;
        *) echo "Please open $SERVICE_URL manually in your browser" ;;
    esac
    echo
}

check_pods() {
    echo
    echo "=== Checking Pod Status ==="
    kubectl get pods -l app=ml-inference-service -o wide
    echo
    echo "=== Pod Details ==="
    kubectl describe pods -l app=ml-inference-service
    echo
}

view_logs() {
    echo
    echo "=== Pod Logs ==="
    echo
    echo "Choose log option:"
    echo "1. Current logs"
    echo "2. Follow logs (live)"
    echo
    read -p "Enter choice (1-2): " log_choice

    case $log_choice in
        1)
            kubectl logs -l app=ml-inference-service --tail=50
            ;;
        2)
            echo "[INFO] Press Ctrl+C to stop following logs"
            kubectl logs -l app=ml-inference-service -f
            ;;
        *)
            echo "Invalid choice"
            ;;
    esac
    echo
}

port_forward() {
    echo
    echo "=== Port Forwarding (Alternative Access) ==="
    echo
    echo "This will forward local port 8080 to the service"
    echo "Access the service at: http://localhost:8080"
    echo
    echo "Press Ctrl+C to stop port forwarding"
    kubectl port-forward service/ml-inference-service-clusterip 8080:80
    echo
}

service_details() {
    echo
    echo "=== Service Details ==="
    echo
    echo "NodePort Service:"
    kubectl describe service ml-inference-service
    echo
    echo "ClusterIP Service:"
    kubectl describe service ml-inference-service-clusterip
    echo
}

show_summary() {
    echo
    echo "=== Summary ==="
    echo
    echo "Your ML API is accessible at: $SERVICE_URL"
    echo
    echo "🚀 Quick Test Commands:"
    echo "  curl $SERVICE_URL/health"
    echo "  curl $SERVICE_URL/model/info"
    echo
    echo "Goodbye!"
}

# Main execution
check_minikube
get_access_info
check_service
show_urls

while true; do
    show_menu
    read -p "Enter your choice (0-9): " choice
    
    case $choice in
        1) test_health; read -p "Press Enter to continue..." ;;
        2) get_model_info; read -p "Press Enter to continue..." ;;
        3) make_prediction; read -p "Press Enter to continue..." ;;
        4) view_metrics; read -p "Press Enter to continue..." ;;
        5) open_browser; read -p "Press Enter to continue..." ;;
        6) check_pods; read -p "Press Enter to continue..." ;;
        7) view_logs; read -p "Press Enter to continue..." ;;
        8) port_forward; read -p "Press Enter to continue..." ;;
        9) service_details; read -p "Press Enter to continue..." ;;
        0) show_summary; exit 0 ;;
        *) echo "Invalid option. Please try again."; sleep 1 ;;
    esac
done