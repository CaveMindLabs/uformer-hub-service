# This script automates the setup and launch for the Uformer Hub Service on Windows.
# It is idempotent, meaning it can be run safely multiple times.

Write-Host "`n--- Starting Uformer Hub Service Setup & Launch ---" -ForegroundColor Green

# Step 1: Create required directories
Write-Host "`n[1/5] Creating required directories..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "backend/model_weights/official_pretrained" | Out-Null
New-Item -ItemType Directory -Force -Path "backend/temp" | Out-Null
New-Item -ItemType Directory -Force -Path "backend/debug_logs" | Out-Null
Write-Host "Directories checked/created."

# Step 2: Define Models and Directory
$modelDir = "backend/model_weights/official_pretrained"
$models = @{
    "Uformer_B_SIDD.pth"           = "https://huggingface.co/CaveMindLabs/uformer-restoration-models/resolve/main/Uformer_B_SIDD.pth?download=true"
    "uformer16_denoising_sidd.pth" = "https://huggingface.co/CaveMindLabs/uformer-restoration-models/resolve/main/uformer16_denoising_sidd.pth?download=true"
    "Uformer_B_GoPro.pth"          = "https://huggingface.co/CaveMindLabs/uformer-restoration-models/resolve/main/Uformer_B_GoPro.pth?download=true"
}

# Step 3: Download Model Weights if they don't exist
Write-Host "`n[2/5] Checking and downloading model weights..." -ForegroundColor Cyan
foreach ($model in $models.Keys) {
    $filePath = Join-Path $modelDir $model
    if (-not (Test-Path $filePath)) {
        Write-Host "Downloading $model..."
        Invoke-WebRequest -Uri $models[$model] -OutFile $filePath
    } else {
        Write-Host "$model already exists. Skipping download." -ForegroundColor Yellow
    }
}
Write-Host "Model check complete."

# Step 4: Configure Environment
Write-Host "`n[3/5] Setting up environment file..." -ForegroundColor Cyan
if (Test-Path "backend/.env") {
    Write-Host "backend/.env file already exists. Skipping creation." -ForegroundColor Yellow
} else {
    Copy-Item "backend/.env.example" "backend/.env"
    Write-Host "backend/.env created successfully."
}

# Step 5: Start the application with Docker Compose
Write-Host "`n[4/5] Starting application services with Docker Compose..." -ForegroundColor Cyan
docker-compose up -d

Write-Host "`n[5/5] Printing application URLs..." -ForegroundColor Cyan
Start-Sleep -Seconds 5 # Give containers a moment to initialize before printing links

Write-Host "`n--- SETUP & LAUNCH COMPLETE ---" -ForegroundColor Green
Write-Host "Your services are running in the background."
Write-Host "-----------------------------------------"
Write-Host "Next.js Frontend: http://localhost:3000" -ForegroundColor White
Write-Host "Backend Docs:     http://localhost:8000/docs" -ForegroundColor White
Write-Host "Backend ReDoc:    http://localhost:8000/redoc" -ForegroundColor White
Write-Host "-----------------------------------------"
