#!/bin/bash

# Make the script executable
chmod +x "$0"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Docker
install_docker() {
    echo "Docker not found. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    # Start Docker service
    sudo systemctl start docker
    # Wait for Docker to be ready
    while ! docker info >/dev/null 2>&1; do
        echo "Waiting for Docker to start..."
        sleep 1
    done
    echo "Docker installed and started successfully."
}

# Function to install Docker Compose
install_docker_compose() {
    echo "Docker Compose not found. Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installed successfully."
}

# Check and install Docker if necessary
if ! command_exists docker; then
    install_docker
fi

# Check and install Docker Compose if necessary
if ! command_exists docker-compose; then
    install_docker_compose
fi

# Create project directory
mkdir -p belullama && cd belullama

# Create Docker Compose file
cat > docker-compose.yml << EOL
version: '3'

services:
  ollama:
    image: ollama/ollama:latest
    command: serve
    ports:
      - "11434:11434"
    restart: unless-stopped
    volumes:
      - ./ollama_data:/root/.ollama

  webui:
    image: ghcr.io/ai-joe-git/open-webui:latest
    environment:
      - OLLAMA_BASE_URL=http://ollama:11434
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
    image: ghcr.io/ai-joe-git/automatic1111-docker:main
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
EOL

# Create necessary directories
mkdir -p ollama_data webui_data sd_models sd_vae sd_lora sd_embeddings sd_outputs sd_config

# Run Docker Compose
echo "Starting Belullama services..."
docker-compose up -d

echo "Belullama is now running!"
echo "Access the services at:"
echo "- Ollama API: http://localhost:11434"
echo "- WebUI: http://localhost:8080"
echo "- Stable Diffusion WebUI: http://localhost:7860"
