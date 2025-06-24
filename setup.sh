#!/bin/bash

# This script automates the setup and launch for the Uformer Hub Service.
# It is idempotent, meaning it can be run safely multiple times.

# --- ANSI Color Codes ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}--- Starting Uformer Hub Service Setup & Launch ---${NC}\n"

# Step 1: Create required directories
echo -e "${CYAN}[1/5] Creating required directories...${NC}"
mkdir -p backend/model_weights/official_pretrained backend/temp backend/debug_logs
echo -e "Directories checked/created.\n"

# Step 2: Define Models and Directory
MODEL_DIR="backend/model_weights/official_pretrained"
declare -A models=(
    ["Uformer_B_SIDD.pth"]="https://huggingface.co/CaveMindLabs/uformer-restoration-models/resolve/main/Uformer_B_SIDD.pth?download=true"
    ["uformer16_denoising_sidd.pth"]="https://huggingface.co/CaveMindLabs/uformer-restoration-models/resolve/main/uformer16_denoising_sidd.pth?download=true"
    ["Uformer_B_GoPro.pth"]="https://huggingface.co/CaveMindLabs/uformer-restoration-models/resolve/main/Uformer_B_GoPro.pth?download=true"
)

# Step 3: Download Model Weights if they don't exist
echo -e "${CYAN}[2/5] Checking and downloading model weights...${NC}"
for model in "${!models[@]}"; do
    if [ ! -f "$MODEL_DIR/$model" ]; then
        echo "Downloading $model..."
        curl -L "${models[$model]}" -o "$MODEL_DIR/$model"
    else
        echo -e "${YELLOW}$model already exists. Skipping download.${NC}"
    fi
done
echo -e "Model check complete.\n"

# Step 4: Configure Environment
echo -e "${CYAN}[3/5] Setting up environment file...${NC}"
if [ -f "backend/.env" ]; then
    echo -e "${YELLOW}backend/.env file already exists. Skipping creation.${NC}"
else
    cp backend/.env.example backend/.env
    echo "backend/.env created successfully."
fi
echo ""

# Step 5: Start the application with Docker Compose
echo -e "${CYAN}[4/5] Starting application services with Docker Compose...${NC}"
docker-compose up -d

echo ""
echo -e "${CYAN}[5/5] Printing application URLs...${NC}"
sleep 5 # Give containers a moment to initialize before printing links

echo -e "\n${GREEN}--- SETUP & LAUNCH COMPLETE ---${NC}"
echo "Your services are running in the background."
echo "-----------------------------------------"
echo -e "Next.js Frontend: http://localhost:3000"
echo -e "Backend Docs:     http://localhost:8000/docs"
echo -e "Backend ReDoc:    http://localhost:8000/redoc"
echo -e "-----------------------------------------\n"
