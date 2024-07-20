#!/bin/bash

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    printf "${!1}%s${NC}\n" "$2"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Docker
install_docker() {
    print_color "YELLOW" "Docker not found. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    sudo systemctl start docker
    while ! docker info >/dev/null 2>&1; do
        echo -n "."
        sleep 1
    done
    print_color "GREEN" "Docker installed and started successfully."
}

# Function to install Docker Compose
install_docker_compose() {
    print_color "YELLOW" "Docker Compose not found. Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_color "GREEN" "Docker Compose installed successfully."
}

# Function to get all IP addresses
get_ip_addresses() {
    ip -4 addr | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1'
}

# Function to get hostname
get_hostname() {
    hostname
}

# Function to get FQDN (Fully Qualified Domain Name)
get_fqdn() {
    hostname -f
}

# Print welcome message
print_color "BLUE" "
╔═══════════════════════════════════════════╗
║         Welcome to Belullama Setup        ║
╚═══════════════════════════════════════════╝"

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    print_color "RED" "Please run as root or with sudo privileges."
    exit 1
fi

# Check and install Docker if necessary
if ! command_exists docker; then
    install_docker
else
    print_color "GREEN" "Docker is already installed."
fi

# Check and install Docker Compose if necessary
if ! command_exists docker-compose; then
    install_docker_compose
else
    print_color "GREEN" "Docker Compose is already installed."
fi

# Create project directory
INSTALL_DIR="$HOME/belullama"
mkdir -p "$INSTALL_DIR" && cd "$INSTALL_DIR"
print_color "BLUE" "Installing Belullama in $INSTALL_DIR"

# Create Docker Compose file
print_color "YELLOW" "Creating Docker Compose configuration..."
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
print_color "YELLOW" "Creating data directories..."
mkdir -p ollama_data webui_data sd_models sd_vae sd_lora sd_embeddings sd_outputs sd_config

# Run Docker Compose
print_color "BLUE" "Starting Belullama services..."
docker-compose up -d

# Check if services are running
if [ $? -eq 0 ]; then
    print_color "GREEN" "
╔═══════════════════════════════════════════╗
║      Belullama is now up and running!     ║
╚═══════════════════════════════════════════╝

Belullama services are accessible at the following addresses:

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

    print_color "BLUE" "
You can use any of these addresses to access Belullama services from devices on your network.
Choose the option that works best for your network configuration.

Thank you for using Belullama!"
else
    print_color "RED" "There was an issue starting Belullama services. Please check the Docker logs for more information."
fi
