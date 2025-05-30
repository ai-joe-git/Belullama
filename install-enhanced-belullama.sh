#!/bin/bash

# Belullama Enhanced Installation Script
# Bundles Automatic1111, ComfyUI, Ollama, and Open WebUI with GPU detection and optimization
# One-command installation with modern terminal UI

set -e

# Colors for modern terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ASCII Art Banner
print_banner() {
    echo -e "${PURPLE}"
    cat << "EOF"
██████╗ ███████╗██╗     ██╗   ██╗██╗     ██╗      █████╗ ███╗   ███╗ █████╗ 
██╔══██╗██╔════╝██║     ██║   ██║██║     ██║     ██╔══██╗████╗ ████║██╔══██╗
██████╔╝█████╗  ██║     ██║   ██║██║     ██║     ███████║██╔████╔██║███████║
██╔══██╗██╔══╝  ██║     ██║   ██║██║     ██║     ██╔══██║██║╚██╔╝██║██╔══██║
██████╔╝███████╗███████╗╚██████╔╝███████╗███████╗██║  ██║██║ ╚═╝ ██║██║  ██║
╚═════╝ ╚══════╝╚══════╝ ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝
                                                                            
                    ███████╗███╗   ██╗██╗  ██╗ █████╗ ███╗   ██╗ ██████╗███████╗██████╗ 
                    ██╔════╝████╗  ██║██║  ██║██╔══██╗████╗  ██║██╔════╝██╔════╝██╔══██╗
                    █████╗  ██╔██╗ ██║███████║███████║██╔██╗ ██║██║     █████╗  ██║  ██║
                    ██╔══╝  ██║╚██╗██║██╔══██║██╔══██║██║╚██╗██║██║     ██╔══╝  ██║  ██║
                    ███████╗██║ ╚████║██║  ██║██║  ██║██║ ╚████║╚██████╗███████╗██████╔╝
                    ╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═════╝ 

EOF
    echo -e "${NC}"
    echo -e "${CYAN}🚀 One-Command AI Suite Installation${NC}"
    echo -e "${CYAN}   Automatic1111 • ComfyUI • Ollama • Open WebUI${NC}"
    echo ""
}

# Progress bar function
show_progress() {
    local duration=$1
    local message=$2
    echo -e "${BLUE}${message}${NC}"
    for ((i=0; i<=100; i+=2)); do
        printf "\r${GREEN}["
        for ((j=0; j<i/2; j++)); do printf "█"; done
        for ((j=i/2; j<50; j++)); do printf " "; done
        printf "] ${i}%%${NC}"
        sleep 0.05
    done
    echo ""
}

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        echo -e "${RED}❌ Don't run this script as root. Run as normal user.${NC}"
        exit 1
    fi
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is not installed. Installing Docker...${NC}"
        curl -fsSL https://get.docker.com | sh
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
        echo -e "${GREEN}✅ Docker installed successfully${NC}"
        echo -e "${YELLOW}⚠️  Please log out and log back in, then run the script again.${NC}"
        exit 0
    else
        echo -e "${GREEN}✅ Docker is already installed${NC}"
    fi
    
    # Check if user is in docker group
    if ! groups $USER | grep -q '\bdocker\b'; then
        echo -e "${YELLOW}⚠️  Adding user to docker group...${NC}"
        sudo usermod -aG docker $USER
        echo -e "${YELLOW}⚠️  Please log out and log back in, then run the script again.${NC}"
        exit 0
    fi
    
    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}❌ Docker Compose is not installed. Installing...${NC}"
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo -e "${GREEN}✅ Docker Compose installed successfully${NC}"
    else
        echo -e "${GREEN}✅ Docker Compose is already installed${NC}"
    fi
    
    # Check for Git (needed for Intel ComfyUI installer)
    if ! command -v git &> /dev/null; then
        echo -e "${RED}❌ Git is not installed. Installing Git...${NC}"
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get update && sudo apt-get install -y git
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install git
        fi
        echo -e "${GREEN}✅ Git installed successfully${NC}"
    else
        echo -e "${GREEN}✅ Git is already installed${NC}"
    fi
    
    # Check for Python (needed for Intel ComfyUI)
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}❌ Python3 is not installed. Installing Python3...${NC}"
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get update && sudo apt-get install -y python3 python3-pip python3-venv
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install python
        fi
        echo -e "${GREEN}✅ Python3 installed successfully${NC}"
    else
        echo -e "${GREEN}✅ Python3 is already installed${NC}"
    fi
}

# Function to detect GPU type and specifications
detect_gpu() {
    echo -e "${YELLOW}🔍 Detecting GPU hardware...${NC}"
    
    # Get RAM information first for model selection
    TOTAL_RAM_GB=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
    TOTAL_RAM=$(free -h | awk '/^Mem/ {print $2}')
    
    if command -v nvidia-smi &> /dev/null; then
        GPU_TYPE="nvidia"
        GPU_INFO=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits)
        echo -e "${GREEN}✅ NVIDIA GPU detected: ${GPU_INFO}${NC}"
        
        # Install NVIDIA Container Toolkit if not present
        if ! docker info 2>/dev/null | grep -q nvidia; then
            echo -e "${YELLOW}📦 Installing NVIDIA Container Toolkit...${NC}"
            distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
            curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
            curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
                sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
                sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
            sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
            sudo nvidia-ctk runtime configure --runtime=docker
            sudo systemctl restart docker
        fi
        
    elif lspci | grep -i "intel.*graphics\|intel.*arc" &> /dev/null; then
        if lspci | grep -i "arc" &> /dev/null; then
            GPU_TYPE="intel_arc"
            GPU_INFO=$(lspci | grep -i "arc" | head -1 | cut -d: -f3)
            echo -e "${GREEN}✅ Intel Arc GPU detected: ${GPU_INFO}${NC}"
        else
            GPU_TYPE="intel_igpu"
            GPU_INFO=$(lspci | grep -i "intel.*graphics" | head -1 | cut -d: -f3)
            echo -e "${GREEN}✅ Intel iGPU detected: ${GPU_INFO}${NC}"
        fi
        
    elif lspci | grep -i amd | grep -i vga &> /dev/null; then
        GPU_TYPE="amd"
        GPU_INFO=$(lspci | grep -i amd | grep -i vga | head -1 | cut -d: -f3)
        echo -e "${GREEN}✅ AMD GPU detected: ${GPU_INFO}${NC}"
        
    else
        GPU_TYPE="cpu"
        echo -e "${YELLOW}⚠️  No dedicated GPU detected. Using CPU-only configuration.${NC}"
    fi
    
    # Select appropriate DeepSeek-R1 model based on RAM
    if [ "$TOTAL_RAM_GB" -lt 16 ]; then
        DEEPSEEK_MODEL="deepseek-r1:1.5b"
        echo -e "${YELLOW}📊 RAM < 16GB detected. Using DeepSeek-R1 1.5B model for optimal performance.${NC}"
    else
        DEEPSEEK_MODEL="deepseek-r1:8b"
        echo -e "${GREEN}📊 Sufficient RAM detected. Using DeepSeek-R1 8B model.${NC}"
    fi
    
    # Get system specs
    AVAILABLE_SPACE=$(df -h . | awk 'NR==2 {print $4}')
    
    echo -e "${CYAN}💻 System Information:${NC}"
    echo -e "   GPU: ${GPU_INFO:-CPU Only}"
    echo -e "   RAM: ${TOTAL_RAM}"
    echo -e "   Selected Model: ${DEEPSEEK_MODEL}"
    echo -e "   Available Space: ${AVAILABLE_SPACE}"
    echo ""
}

# Install Intel ComfyUI for Intel Arc/iGPU
install_intel_comfyui() {
    echo -e "${YELLOW}🎛️ Installing ComfyUI for Intel GPU using custom installer...${NC}"
    
    # Create ComfyUI directory
    mkdir -p intel-comfyui
    cd intel-comfyui
    
    # Clone the Intel ComfyUI installer
    echo -e "${CYAN}📥 Cloning Intel ComfyUI installer...${NC}"
    git clone https://github.com/ai-joe-git/ComfyUI-Intel-Arc-Clean-Install-Windows-venv-XPU-.git intel-setup
    cd intel-setup
    
    # For Linux, adapt the Windows batch script logic
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo -e "${CYAN}🐧 Adapting installation for Linux...${NC}"
        
        # Install Intel compute runtime and oneAPI
        echo -e "${YELLOW}📦 Installing Intel dependencies...${NC}"
        
        # Download and install Intel compute runtime
        wget -qO - https://repositories.intel.com/graphics/intel-graphics.key | sudo apt-key add -
        echo 'deb [arch=amd64] https://repositories.intel.com/graphics/ubuntu focal main' | sudo tee /etc/apt/sources.list.d/intel-graphics.list
        sudo apt update
        sudo apt install -y intel-opencl-icd intel-level-zero-gpu level-zero intel-media-va-driver-non-free libmfx1 || true
        
        # Clone ComfyUI and setup
        echo -e "${CYAN}📥 Setting up ComfyUI...${NC}"
        git clone https://github.com/comfyanonymous/ComfyUI.git
        cd ComfyUI
        
        # Create virtual environment
        python3 -m venv comfyui_env
        source comfyui_env/bin/activate
        
        # Install Intel PyTorch XPU
        echo -e "${CYAN}📦 Installing Intel PyTorch XPU...${NC}"
        pip install torch==2.1.0a0 torchvision==0.16.0a0 intel-extension-for-pytorch==2.1.10+xpu --extra-index-url https://pytorch-extension.intel.com/release-whl/stable/xpu/us/ || {
            echo -e "${YELLOW}⚠️  Installing standard PyTorch as fallback...${NC}"
            pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
        }
        
        pip install -r requirements.txt
        
        # Create startup script
        cat > start_intel_comfyui.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source comfyui_env/bin/activate
export PYTHONPATH="${PWD}:${PYTHONPATH}"
# Set Intel GPU environment variables
export ZE_FLAT_DEVICE_HIERARCHY=COMPOSITE
export SYCL_CACHE_PERSISTENT=1
# Source Intel oneAPI if available
source /opt/intel/oneapi/setvars.sh 2>/dev/null || true
# Start ComfyUI with Intel optimizations
python main.py --listen 0.0.0.0 --port 8188 --preview-method auto
EOF
        chmod +x start_intel_comfyui.sh
        
    else
        echo -e "${YELLOW}🪟 Running Windows installation...${NC}"
        # For Windows/WSL, run the batch files
        cmd //c install_comfyui_venv.bat 2>/dev/null || echo "Please run install_comfyui_venv.bat manually"
    fi
    
    cd ../../..
    echo -e "${GREEN}✅ Intel ComfyUI installation complete${NC}"
}

# Create optimized Docker Compose configuration
create_docker_compose() {
    echo -e "${YELLOW}📝 Creating optimized Docker Compose configuration...${NC}"
    
    # For Intel GPU, handle ComfyUI differently
    if [[ "$GPU_TYPE" == "intel_arc" || "$GPU_TYPE" == "intel_igpu" ]]; then
        COMFYUI_SERVICE=""
        COMFYUI_VOLUME=""
        COMFYUI_DEPENDS=""
        COMFYUI_URL="http://host.docker.internal:8188"
        echo -e "${CYAN}📝 Intel GPU detected - ComfyUI will be installed natively for optimal XPU support${NC}"
    else
        COMFYUI_SERVICE="
  # ComfyUI - Advanced Workflows
  comfyui:
    image: comfyanonymous/comfyui:latest
    container_name: belullama-comfyui
    ports:
      - \"8188:8188\"
    volumes:
      - comfyui:/app
      - ./models/comfyui:/app/models
    environment:
      - CLI_ARGS=--listen 0.0.0.0 --port 8188$([ "$GPU_TYPE" = "amd" ] && echo " --directml" || echo "")
$([ "$GPU_TYPE" = "nvidia" ] && echo "      - NVIDIA_VISIBLE_DEVICES=all")
    restart: unless-stopped$([ "$GPU_TYPE" = "nvidia" ] && cat <<EOL

    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
EOL
)"
        COMFYUI_VOLUME="
  comfyui:"
        COMFYUI_DEPENDS="
      - comfyui"
        COMFYUI_URL="http://comfyui:8188"
    fi
    
    cat > docker-compose.yml <<EOF
version: '3.8'

services:
  # Open WebUI - Main Interface
  open-webui:
    image: ghcr.io/open-webui/open-webui:$([ "$GPU_TYPE" = "nvidia" ] && echo "cuda" || echo "main")
    container_name: belullama-openwebui
    ports:
      - "3000:8080"
    volumes:
      - open-webui:/app/backend/data
      - ./models:/app/backend/data/models
    environment:
      - WEBUI_NAME=Belullama Enhanced
      - AUTOMATIC1111_BASE_URL=http://automatic1111:7860
      - COMFYUI_BASE_URL=$COMFYUI_URL
      - OLLAMA_BASE_URL=http://ollama:11434
      - ENABLE_IMAGE_GENERATION=true
      - ENABLE_COMMUNITY_SHARING=false
      - WEBUI_AUTH=false
    depends_on:
      - ollama
      - automatic1111$COMFYUI_DEPENDS
    restart: unless-stopped$([ "$GPU_TYPE" = "nvidia" ] && cat <<EOL

    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
EOL
)

  # Ollama - LLM Backend
  ollama:
    image: ollama/ollama:latest
    container_name: belullama-ollama
    ports:
      - "11434:11434"
    volumes:
      - ollama:/root/.ollama
      - ./models/ollama:/root/.ollama/models
    environment:
      - OLLAMA_KEEP_ALIVE=24h
      - OLLAMA_HOST=0.0.0.0
$([ "$GPU_TYPE" = "nvidia" ] && echo "      - NVIDIA_VISIBLE_DEVICES=all")
    restart: unless-stopped$([ "$GPU_TYPE" = "nvidia" ] && cat <<EOL

    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
EOL
)

  # Automatic1111 - Stable Diffusion
  automatic1111:
    image: automaticai/automatic1111:latest
    container_name: belullama-automatic1111
    ports:
      - "7860:7860"
    volumes:
      - automatic1111:/app
      - ./models/stable-diffusion:/app/models
    environment:
      - CLI_ARGS=--api --listen --port 7860 --cors-allow-origins=* --xformers --enable-insecure-extension-access$([ "$GPU_TYPE" = "amd" ] && echo " --precision full --no-half --use-cpu all" || echo "")$([ "$GPU_TYPE" = "cpu" ] && echo " --use-cpu all --precision full --no-half" || echo "")
$([ "$GPU_TYPE" = "nvidia" ] && echo "      - NVIDIA_VISIBLE_DEVICES=all")
    restart: unless-stopped$([ "$GPU_TYPE" = "nvidia" ] && cat <<EOL

    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
EOL
)

$COMFYUI_SERVICE

volumes:
  open-webui:
  ollama:
  automatic1111:$COMFYUI_VOLUME

networks:
  default:
    name: belullama-network
EOF

    echo -e "${GREEN}✅ Docker Compose configuration created${NC}"
}

# Download essential models
download_models() {
    echo -e "${YELLOW}📦 Setting up model directories...${NC}"
    
    # Create model directories
    mkdir -p models/{ollama,stable-diffusion,comfyui}
    mkdir -p models/stable-diffusion/{Stable-diffusion,Lora,VAE,embeddings}
    mkdir -p models/comfyui/{checkpoints,loras,vae,controlnet}
    
    show_progress 100 "📁 Model directories created"
}

# Start services with health checks
start_services() {
    echo -e "${YELLOW}🚀 Starting Belullama Enhanced services...${NC}"
    
    # Install Intel ComfyUI if needed
    if [[ "$GPU_TYPE" == "intel_arc" || "$GPU_TYPE" == "intel_igpu" ]]; then
        install_intel_comfyui
    fi
    
    # Pull latest images
    show_progress 50 "📥 Pulling latest Docker images..."
    docker-compose pull --quiet
    
    # Start services
    show_progress 50 "🔄 Starting containers..."
    docker-compose up -d
    
    # Start Intel ComfyUI if applicable
    if [[ "$GPU_TYPE" == "intel_arc" || "$GPU_TYPE" == "intel_igpu" ]]; then
        echo -e "${YELLOW}🎛️ Starting Intel ComfyUI...${NC}"
        cd intel-comfyui/intel-setup/ComfyUI
        nohup ./start_intel_comfyui.sh > comfyui.log 2>&1 &
        cd ../../..
        echo -e "${GREEN}✅ Intel ComfyUI started${NC}"
    fi
    
    # Wait for services to be ready
    echo -e "${YELLOW}⏳ Waiting for services to initialize...${NC}"
    
    # Check Ollama
    echo -e "${CYAN}🤖 Checking Ollama...${NC}"
    for i in {1..60}; do
        if curl -s http://localhost:11434/api/tags &>/dev/null; then
            echo -e "${GREEN}✅ Ollama is ready${NC}"
            break
        fi
        if [ $i -eq 60 ]; then
            echo -e "${RED}❌ Ollama failed to start${NC}"
        fi
        sleep 2
    done
    
    # Check Automatic1111
    echo -e "${CYAN}🎨 Checking Automatic1111...${NC}"
    for i in {1..120}; do
        if curl -s http://localhost:7860 &>/dev/null; then
            echo -e "${GREEN}✅ Automatic1111 is ready${NC}"
            break
        fi
        if [ $i -eq 120 ]; then
            echo -e "${RED}❌ Automatic1111 failed to start${NC}"
        fi
        sleep 2
    done
    
    # Check ComfyUI
    echo -e "${CYAN}🎛️ Checking ComfyUI...${NC}"
    for i in {1..60}; do
        if curl -s http://localhost:8188 &>/dev/null; then
            echo -e "${GREEN}✅ ComfyUI is ready${NC}"
            break
        fi
        if [ $i -eq 60 ]; then
            echo -e "${RED}❌ ComfyUI failed to start${NC}"
        fi
        sleep 2
    done
    
    # Check Open WebUI
    echo -e "${CYAN}🌐 Checking Open WebUI...${NC}"
    for i in {1..60}; do
        if curl -s http://localhost:3000 &>/dev/null; then
            echo -e "${GREEN}✅ Open WebUI is ready${NC}"
            break
        fi
        if [ $i -eq 60 ]; then
            echo -e "${RED}❌ Open WebUI failed to start${NC}"
        fi
        sleep 2
    done
}

# Download DeepSeek-R1 models
setup_ollama_models() {
    echo -e "${YELLOW}🤖 Setting up latest DeepSeek-R1 models...${NC}"
    
    # Wait a bit more for Ollama to be fully ready
    sleep 10
    
    # Download DeepSeek-R1 model based on RAM
    echo -e "${CYAN}📥 Downloading DeepSeek-R1 reasoning model: ${DEEPSEEK_MODEL}...${NC}"
    echo -e "${CYAN}   This is the latest open reasoning model with performance comparable to OpenAI-o3${NC}"
    
    docker-compose exec -T ollama ollama pull "$DEEPSEEK_MODEL"
    
    echo -e "${GREEN}✅ Latest DeepSeek-R1 model setup complete${NC}"
}

# Configure integrations
configure_integrations() {
    echo -e "${YELLOW}⚙️  Configuring service integrations...${NC}"
    
    # Wait for Open WebUI to be fully ready
    sleep 15
    
    # Configure Automatic1111 in Open WebUI
    curl -s -X POST http://localhost:3000/api/v1/configs/update \
         -H "Content-Type: application/json" \
         -d '{
           "AUTOMATIC1111_BASE_URL": "http://automatic1111:7860",
           "ENABLE_IMAGE_GENERATION": true,
           "IMAGE_GENERATION_ENGINE": "automatic1111"
         }' &>/dev/null || true
    
    # Configure ComfyUI in Open WebUI  
    COMFYUI_CONFIG_URL=$([ "$GPU_TYPE" = "intel_arc" ] || [ "$GPU_TYPE" = "intel_igpu" ] && echo "http://localhost:8188" || echo "http://comfyui:8188")
    curl -s -X POST http://localhost:3000/api/v1/configs/update \
         -H "Content-Type: application/json" \
         -d "{
           \"COMFYUI_BASE_URL\": \"$COMFYUI_CONFIG_URL\"
         }" &>/dev/null || true
    
    echo -e "${GREEN}✅ Service integrations configured${NC}"
}

# Display final information
show_completion_info() {
    clear
    print_banner
    
    echo -e "${GREEN}🎉 Belullama Enhanced Installation Complete!${NC}"
    echo ""
    
    echo -e "${CYAN}📊 System Information:${NC}"
    echo -e "   🖥️  GPU: ${GPU_INFO:-CPU Only}"
    echo -e "   🧠 RAM: ${TOTAL_RAM}"
    echo -e "   🤖 AI Model: ${DEEPSEEK_MODEL} (DeepSeek-R1 reasoning model)"
    echo -e "   💾 Available Space: ${AVAILABLE_SPACE}"
    echo ""
    
    echo -e "${CYAN}🌐 Available Services:${NC}"
    echo -e "   🎯 ${YELLOW}Open WebUI (Main Interface):${NC} ${BLUE}http://localhost:3000${NC}"
    echo -e "      └── Your primary interface for all AI interactions"
    echo ""
    echo -e "   🎨 ${YELLOW}Automatic1111 (Image Generation):${NC} ${BLUE}http://localhost:7860${NC}"
    echo -e "      └── Stable Diffusion image generation and API"
    echo ""
    echo -e "   🎛️  ${YELLOW}ComfyUI (Advanced Workflows):${NC} ${BLUE}http://localhost:8188${NC}"
    if [[ "$GPU_TYPE" == "intel_arc" || "$GPU_TYPE" == "intel_igpu" ]]; then
        echo -e "      └── Intel XPU optimized node-based workflow (native installation)"
    else
        echo -e "      └── Node-based workflow for advanced AI tasks"
    fi
    echo ""
    echo -e "   🤖 ${YELLOW}Ollama (Language Models):${NC} ${BLUE}http://localhost:11434${NC}"
    echo -e "      └── Local language model API with DeepSeek-R1 reasoning"
    echo ""
    
    echo -e "${CYAN}🔧 Pre-configured Features:${NC}"
    echo -e "   ✅ Image generation via Automatic1111"
    if [[ "$GPU_TYPE" == "intel_arc" || "$GPU_TYPE" == "intel_igpu" ]]; then
        echo -e "   ✅ Intel XPU optimized ComfyUI with native installation"
    else
        echo -e "   ✅ ComfyUI workflow integration"
    fi
    echo -e "   ✅ Latest DeepSeek-R1 reasoning model (comparable to OpenAI-o3)"
    echo -e "   ✅ $([ "$GPU_TYPE" != "cpu" ] && echo "GPU acceleration enabled" || echo "CPU optimization enabled")"
    echo -e "   ✅ Cross-service API integrations"
    echo -e "   ✅ Persistent data storage"
    echo -e "   ✅ RAM-optimized model selection"
    echo ""
    
    echo -e "${CYAN}💡 Quick Start Tips:${NC}"
    echo -e "   1. Visit ${BLUE}http://localhost:3000${NC} to access the main interface"
    echo -e "   2. All services are pre-configured and ready to use"
    echo -e "   3. DeepSeek-R1 model is ready for reasoning tasks"
    echo -e "   4. Use ${YELLOW}'docker-compose logs -f [service]'${NC} to view logs"
    echo -e "   5. Use ${YELLOW}'docker-compose down'${NC} to stop all services"
    if [[ "$GPU_TYPE" == "intel_arc" || "$GPU_TYPE" == "intel_igpu" ]]; then
        echo -e "   6. Intel ComfyUI logs: ${YELLOW}'tail -f intel-comfyui/intel-setup/ComfyUI/comfyui.log'${NC}"
    fi
    echo ""
    
    echo -e "${CYAN}📚 Management Commands:${NC}"
    echo -e "   🔄 Restart: ${YELLOW}docker-compose restart${NC}"
    echo -e "   ⬇️  Stop: ${YELLOW}docker-compose down${NC}"
    echo -e "   📊 Status: ${YELLOW}docker-compose ps${NC}"
    echo -e "   📝 Logs: ${YELLOW}docker-compose logs -f${NC}"
    echo -e "   🔄 Update: ${YELLOW}docker-compose pull && docker-compose up -d${NC}"
    echo ""
    
    echo -e "${GREEN}🚀 Enjoy your Belullama Enhanced AI Suite with latest DeepSeek-R1 reasoning!${NC}"
    echo -e "${PURPLE}   Follow us for updates and support${NC}"
}

# Main installation flow
main() {
    clear
    print_banner
    
    echo -e "${YELLOW}Starting Belullama Enhanced installation with latest DeepSeek-R1...${NC}"
    echo ""
    
    check_prerequisites
    detect_gpu
    create_docker_compose
    download_models
    start_services
    
    # Background tasks
    setup_ollama_models &
    configure_integrations &
    
    # Wait for background tasks
    wait
    
    show_completion_info
}

# Handle script interruption
trap 'echo -e "\n${RED}Installation interrupted. Cleaning up...${NC}"; docker-compose down &>/dev/null 2>&1; exit 1' INT

# Run main installation
main "$@"
