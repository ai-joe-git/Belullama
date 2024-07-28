#!/bin/bash

# Function to print colored text
print_color() {
    case $1 in
        "RED") printf "\033[0;31m$2\033[0m\n" ;;
        "GREEN") printf "\033[0;32m$2\033[0m\n" ;;
        "YELLOW") printf "\033[1;33m$2\033[0m\n" ;;
    esac
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check for NVIDIA GPU
check_nvidia_gpu() {
    if command_exists nvidia-smi; then
        return 0
    else
        return 1
    fi
}

# Function to check for AMD GPU
check_amd_gpu() {
    if command_exists rocm-smi; then
        return 0
    elif [ -d "/sys/class/kfd" ]; then
        return 0
    else
        return 1
    fi
}

# Function to determine CUDA version
get_cuda_version() {
    if command_exists nvidia-smi; then
        CUDA_VERSION=$(nvidia-smi --query-gpu=cuda_version --format=csv,noheader,nounits | head -n 1)
        echo "${CUDA_VERSION//.}"  # Remove dots from version number
    else
        echo "0"
    fi
}

# Function to install NVIDIA Container Toolkit
install_nvidia_container_toolkit() {
    print_color "YELLOW" "Installing NVIDIA Container Toolkit..."
    if command_exists apt-get; then
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
        curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
        sudo apt-get update
        sudo apt-get install -y nvidia-container-toolkit
    elif command_exists yum; then
        distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
        curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.repo | \
            sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
        sudo yum install -y nvidia-container-toolkit
    else
        print_color "RED" "Unsupported package manager. Please install NVIDIA Container Toolkit manually."
        exit 1
    fi
}

# Function to install ROCm
install_rocm() {
    print_color "YELLOW" "Installing ROCm..."
    if command_exists apt-get; then
        sudo apt-get update
        sudo apt-get install -y rocm-libs
    elif command_exists yum; then
        sudo yum install -y rocm-libs
    else
        print_color "RED" "Unsupported package manager. Please install ROCm manually."
        exit 1
    fi
}

# Function to get hostname
get_hostname() {
    hostname
}

# Function to get FQDN
get_fqdn() {
    hostname -f
}

# Function to get IP addresses
get_ip_addresses() {
    ip -4 addr | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '^127' | sort
}

# Check if Docker is installed
if ! command_exists docker; then
    print_color "RED" "Docker is not installed. Please install Docker and run this script again."
    exit 1
fi

# Check if Docker Compose is installed
if ! command_exists docker-compose; then
    print_color "RED" "Docker Compose is not installed. Please install Docker Compose and run this script again."
    exit 1
fi

# Check for GPU and install necessary drivers/toolkits
GPU_TYPE=""
CUDA_VERSION=""
if check_nvidia_gpu; then
    print_color "GREEN" "NVIDIA GPU detected."
    GPU_TYPE="nvidia"
    if ! command_exists nvidia-container-toolkit; then
        install_nvidia_container_toolkit
    else
        print_color "GREEN" "NVIDIA Container Toolkit is already installed."
    fi
    CUDA_VERSION=$(get_cuda_version)
    print_color "GREEN" "CUDA version: $CUDA_VERSION"
elif check_amd_gpu; then
    print_color "GREEN" "AMD GPU detected."
    GPU_TYPE="amd"
    if ! command_exists rocm-smi; then
        install_rocm
    else
        print_color "GREEN" "ROCm is already installed."
    fi
else
    print_color "YELLOW" "No supported GPU detected. Using CPU-only mode."
    GPU_TYPE="cpu"
fi

# Create project directory
PROJECT_DIR="belullama"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR" || exit

# Create Docker Compose file
print_color "YELLOW" "Creating Docker Compose configuration..."
cat > docker-compose.yml << EOL
version: '3'

services:
  ollama:
EOL

if [ "$GPU_TYPE" = "nvidia" ]; then
    echo "    image: ollama/ollama:latest-cuda${CUDA_VERSION}" >> docker-compose.yml
elif [ "$GPU_TYPE" = "amd" ]; then
    echo "    image: ollama/ollama:latest-rocm" >> docker-compose.yml
else
    echo "    image: ollama/ollama:latest" >> docker-compose.yml
fi

cat >> docker-compose.yml << EOL
    command: serve
    ports:
      - "11434:11434"
    restart: unless-stopped
    volumes:
      - ./ollama_data:/root/.ollama
EOL

if [ "$GPU_TYPE" = "nvidia" ]; then
    echo "    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]" >> docker-compose.yml
elif [ "$GPU_TYPE" = "amd" ]; then
    echo "    devices:
      - /dev/kfd:/dev/kfd
      - /dev/dri:/dev/dri" >> docker-compose.yml
fi

cat >> docker-compose.yml << EOL

  webui:
EOL

if [ "$GPU_TYPE" = "nvidia" ]; then
    echo "    image: ghcr.io/ai-joe-git/open-webui:latest-cuda" >> docker-compose.yml
elif [ "$GPU_TYPE" = "amd" ]; then
    echo "    image: ghcr.io/ai-joe-git/open-webui:latest-rocm" >> docker-compose.yml
else
    echo "    image: ghcr.io/ai-joe-git/open-webui:latest" >> docker-compose.yml
fi

cat >> docker-compose.yml << EOL
    environment:
      - OLLAMA_BASE_URL=http://ollama:11434
      - ENABLE_RAG_WEB_LOADER_SSL_VERIFICATION:true
      - ENABLE_RAG_WEB_SEARCH:true
      - RAG_WEB_SEARCH_ENGINE:duckduckgo
      - ENABLE_IMAGE_GENERATION=true
      - AUTOMATIC1111_BASE_URL=http://stable-diffusion-webui:7860
      - IMAGE_SIZE=512x512
      - IMAGE_STEPS=14
    ports:
      - "8080:8080"
    restart: unless-stopped
    volumes:
      - ./webui_data:/app/backend/data
    depends_on:
      - ollama

  stable-diffusion-webui:
EOL

if [ "$GPU_TYPE" = "nvidia" ]; then
    echo "    image: ghcr.io/ai-joe-git/automatic1111-docker:main-cuda" >> docker-compose.yml
elif [ "$GPU_TYPE" = "amd" ]; then
    echo "    image: ghcr.io/ai-joe-git/automatic1111-docker:main-rocm" >> docker-compose.yml
else
    echo "    image: ghcr.io/ai-joe-git/automatic1111-docker:main" >> docker-compose.yml
fi

cat >> docker-compose.yml << EOL
    container_name: automatic1111-docker
    hostname: automatic1111-docker
    ports:
      - "7860:7860"
    restart: unless-stopped
    volumes:
      - ./sd_models:/DATA/AppData/Stable-Diffusion-WebUI/models
      - ./sd_vae:/DATA/AppData/Stable-Diffusion-WebUI/vae
      - ./sd_lora:/DATA/AppData/Stable-Diffusion-WebUI/lora
      - ./sd_embeddings:/DATA/AppData/Stable-Diffusion-WebUI/embeddings
      - ./sd_outputs:/DATA/AppData/Stable-Diffusion-WebUI/outputs
      - ./sd_config:/DATA/AppData/Stable-Diffusion-WebUI/config
      - ./sd_data:/DATA/AppData/Stable-Diffusion-WebUI
EOL

if [ "$GPU_TYPE" = "nvidia" ]; then
    echo "    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]" >> docker-compose.yml
elif [ "$GPU_TYPE" = "amd" ]; then
    echo "    devices:
      - /dev/kfd:/dev/kfd
      - /dev/dri:/dev/dri" >> docker-compose.yml
fi

print_color "GREEN" "Docker Compose configuration created successfully."

# Create directories for volumes
mkdir -p ollama_data webui_data sd_models sd_vae sd_lora sd_embeddings sd_outputs sd_config sd_data

# Start the containers
print_color "YELLOW" "Starting Docker containers..."
docker-compose up -d

# Check if containers are running
if [ "$(docker-compose ps -q | wc -l)" -eq 3 ]; then
    print_color "GREEN" "All containers are running successfully!"
    
    print_color "GREEN" "BeLLLama services are accessible at the following addresses:

1. Using 'localhost' (only from this machine):
   - Ollama API: http://localhost:11434
   - WebUI: http://localhost:8080
   - Stable Diffusion WebUI: http://localhost:7860

2. Using hostname:"
    
    HOSTNAME=$(get_hostname)
    print_color "YELLOW" "   - http://$HOSTNAME:11434 (Ollama API)
   - http://$HOSTNAME:8080 (WebUI)
   - http://$HOSTNAME:7860 (Stable Diffusion WebUI)"

    FQDN=$(get_fqdn)
    if [ "$FQDN" != "$HOSTNAME" ]; then
        print_color "GREEN" "
3. Using Fully Qualified Domain Name (FQDN):"
        print_color "YELLOW" "   - http://$FQDN:11434 (Ollama API)
   - http://$FQDN:8080 (WebUI)
   - http://$FQDN:7860 (Stable Diffusion WebUI)"
    fi

    print_color "GREEN" "
4. Using IP addresses:"
    IP_ADDRESSES=$(get_ip_addresses)
    i=1
    echo "$IP_ADDRESSES" | while read -r ip; do
        print_color "YELLOW" "   $i. http://$ip:11434 (Ollama API)
      http://$ip:8080 (WebUI)
      http://$ip:7860 (Stable Diffusion WebUI)"
        i=$((i+1))
    done
else
    print_color "RED" "Some containers failed to start. Please check the logs using 'docker-compose logs'."
fi

print_color "YELLOW" "Setup complete!"
