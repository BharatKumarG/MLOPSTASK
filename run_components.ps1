# ML Inference Project - Component Runner (PowerShell)
# Run individual components of the ML project

function Show-Menu {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   ML Inference Project - Component Runner" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Select which component to run:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. 🤖 Train ML Model" -ForegroundColor Green
    Write-Host "2. 🚀 Start API Service (Port 5000)" -ForegroundColor Green
    Write-Host "3. 🧪 Run API Tests" -ForegroundColor Green
    Write-Host "4. 🌐 Start Web Dashboard (Port 8080)" -ForegroundColor Green
    Write-Host "5. 🚀 Full Setup (API + Web Interface)" -ForegroundColor Green
    Write-Host "6. 🐳 Docker Build and Run" -ForegroundColor Green
    Write-Host "7. 📊 View MLflow UI" -ForegroundColor Green
    Write-Host "8. ❓ Show Help Guide" -ForegroundColor Green
    Write-Host "9. 🚪 Exit" -ForegroundColor Red
    Write-Host ""
}

function Start-TrainModel {
    Write-Host "🤖 Training ML Model..." -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    python train_model.py
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Model training completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "❌ Model training failed!" -ForegroundColor Red
    }
    Read-Host "Press Enter to continue"
}

function Start-APIService {
    Write-Host "🚀 Starting API Service on port 5000..." -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to stop the service" -ForegroundColor Magenta
    Write-Host "API will be available at: http://localhost:5000" -ForegroundColor Green
    python app.py
}

function Start-APITests {
    Write-Host "🧪 Running API Tests..." -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    python demo.py
    Read-Host "Press Enter to continue"
}

function Start-WebDashboard {
    Write-Host "🌐 Starting Web Dashboard on port 8080..." -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to stop the service" -ForegroundColor Magenta
    Write-Host "Web Dashboard will be available at: http://localhost:8080" -ForegroundColor Green
    Start-Sleep -Seconds 2
    Start-Process "http://localhost:8080"
    python web_interface.py
}

function Start-FullSetup {
    Write-Host "🚀 Starting Full Setup..." -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "This will start:" -ForegroundColor Green
    Write-Host "  - API Service (Port 5000)" -ForegroundColor White
    Write-Host "  - Web Dashboard (Port 8080)" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to continue"
    
    # Start API in new window
    Start-Process powershell -ArgumentList "-Command", "cd '$PWD'; python app.py; Read-Host 'Press Enter to close'"
    Start-Sleep -Seconds 3
    
    # Start Web Interface in new window
    Start-Process powershell -ArgumentList "-Command", "cd '$PWD'; python web_interface.py; Read-Host 'Press Enter to close'"
    Start-Sleep -Seconds 3
    
    # Open browser
    Start-Process "http://localhost:8080"
    
    Write-Host "✅ Services started! Check the new windows." -ForegroundColor Green
    Read-Host "Press Enter to continue"
}

function Start-Docker {
    Write-Host "🐳 Docker Build and Run..." -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Building Docker image..." -ForegroundColor White
    docker build -t ml-inference .
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Running Docker container..." -ForegroundColor White
        docker run -p 5000:5000 ml-inference
    } else {
        Write-Host "❌ Docker build failed!" -ForegroundColor Red
    }
    Read-Host "Press Enter to continue"
}

function Start-MLflowUI {
    Write-Host "📊 Starting MLflow UI..." -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "MLflow UI will be available at: http://localhost:5000" -ForegroundColor Green
    Start-Process powershell -ArgumentList "-Command", "cd '$PWD'; mlflow ui; Read-Host 'Press Enter to close'"
    Start-Sleep -Seconds 3
    Start-Process "http://localhost:5000"
    Read-Host "Press Enter to continue"
}

function Show-Help {
    Clear-Host
    Write-Host "📖 ML Inference Project Help Guide" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🎯 Recommended Order:" -ForegroundColor Yellow
    Write-Host "1. Train ML Model (Option 1)" -ForegroundColor White
    Write-Host "2. Start API Service (Option 2)" -ForegroundColor White
    Write-Host "3. Test API (Option 3)" -ForegroundColor White
    Write-Host "4. Start Web Dashboard (Option 4)" -ForegroundColor White
    Write-Host ""
    Write-Host "📋 Quick Commands:" -ForegroundColor Yellow
    Write-Host "• Train only:     python train_model.py" -ForegroundColor White
    Write-Host "• API only:       python app.py" -ForegroundColor White
    Write-Host "• Test only:      python demo.py" -ForegroundColor White
    Write-Host "• Web only:       python web_interface.py" -ForegroundColor White
    Write-Host ""
    Write-Host "🌐 URLs:" -ForegroundColor Yellow
    Write-Host "• API Service:    http://localhost:5000" -ForegroundColor White
    Write-Host "• Web Dashboard:  http://localhost:8080" -ForegroundColor White
    Write-Host "• MLflow UI:      http://localhost:5000 (when running)" -ForegroundColor White
    Write-Host ""
    Write-Host "📝 Notes:" -ForegroundColor Yellow
    Write-Host "• Each service runs in its own terminal window" -ForegroundColor White
    Write-Host "• Use Ctrl+C to stop any running service" -ForegroundColor White
    Write-Host "• Make sure ports 5000 and 8080 are available" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

# Main script loop
do {
    Show-Menu
    $choice = Read-Host "Enter your choice (1-9)"
    
    switch ($choice) {
        "1" { Start-TrainModel }
        "2" { Start-APIService }
        "3" { Start-APITests }
        "4" { Start-WebDashboard }
        "5" { Start-FullSetup }
        "6" { Start-Docker }
        "7" { Start-MLflowUI }
        "8" { Show-Help }
        "9" { 
            Write-Host ""
            Write-Host "👋 Goodbye!" -ForegroundColor Green
            exit 
        }
        default { 
            Write-Host ""
            Write-Host "❌ Invalid choice! Please select 1-9." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($true)