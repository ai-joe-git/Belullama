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
      - ./sd_data:/DATA/AppData/Stable-Diffusion-WebUI
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

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get IP addresses
get_ip_addresses() {
    ip addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1'
}

# Set installation directory
INSTALL_DIR="$HOME/belullama"

# Function to install lighttpd if it's not already installed
install_lighttpd() {
    if ! command_exists lighttpd; then
        print_color "YELLOW" "lighttpd is not installed. Attempting to install it..."
        if command_exists apt-get; then
            sudo apt-get update && sudo apt-get install -y lighttpd
        elif command_exists yum; then
            sudo yum install -y lighttpd
        elif command_exists brew; then
            brew install lighttpd
        else
            print_color "RED" "Could not install lighttpd. Please install it manually and run the script again."
            exit 1
        fi
    fi
}

# Function to find lighttpd executable
find_lighttpd() {
    local lighttpd_path

    # Check common locations
    for path in /usr/sbin/lighttpd /usr/local/sbin/lighttpd /opt/homebrew/sbin/lighttpd; do
        if [ -x "$path" ]; then
            lighttpd_path="$path"
            break
        fi
    done

    # If not found in common locations, try to find it
    if [ -z "$lighttpd_path" ]; then
        lighttpd_path=$(sudo find / -name lighttpd -type f -executable 2>/dev/null | head -n 1)
    fi

    echo "$lighttpd_path"
}

# Generate HTML interface and start lighttpd server
generate_and_serve_html_interface() {
    local port=8000
    local interface_dir="$INSTALL_DIR/belullama_interface"
    mkdir -p "$interface_dir"
    
    # Get the first non-localhost IP address
    local ip_address=$(get_ip_addresses | head -n 1)

    cat > "$interface_dir/index.html" << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Belullama Ecosystem</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600&display=swap');
        
        :root {
            --text-color: #ffffff;
            --card-bg: rgba(255, 255, 255, 0.1);
            --primary-color: #0071e3;
            --secondary-color: #06c;
        }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            line-height: 1.6;
            color: var(--text-color);
            background: linear-gradient(135deg, #001f3f, #0074D9, #7FDBFF);
            margin: 0;
            padding: 0;
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }

        .container {
            max-width: 1000px;
            margin: 2rem;
            padding: 2rem;
            background: var(--card-bg);
            border-radius: 20px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.18);
            transition: all 0.3s ease;
        }

        h1 {
            color: var(--text-color);
            font-weight: 600;
            margin-bottom: 1.5rem;
            font-size: 2.5rem;
            text-align: center;
        }

        .services {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
        }

        .service {
            background: rgba(255, 255, 255, 0.1);
            border-radius: 15px;
            padding: 1.5rem;
            transition: all 0.3s ease;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            text-align: center;
        }

        .service:hover {
            transform: translateY(-5px);
            box-shadow: 0 6px 12px rgba(0, 0, 0, 0.15);
        }

        .service h2 {
            color: var(--text-color);
            margin-top: 0;
            font-size: 1.5rem;
            font-weight: 600;
        }

        .logo-placeholder {
            width: 80px;
            height: 80px;
            background-color: rgba(255, 255, 255, 0.2);
            border-radius: 50%;
            margin: 0 auto 1rem;
            display: flex;
            justify-content: center;
            align-items: center;
            font-size: 2rem;
            color: var(--text-color);
        }

        .button {
            display: inline-block;
            background: var(--primary-color);
            color: white;
            padding: 10px 20px;
            text-decoration: none;
            border-radius: 20px;
            font-weight: 500;
            transition: all 0.3s ease;
        }

        .button:hover {
            background: var(--secondary-color);
            transform: scale(1.05);
        }

        .info {
            background: rgba(255, 255, 255, 0.1);
            border-radius: 15px;
            padding: 1.5rem;
            margin-top: 2rem;
        }

        .info h3 {
            color: var(--text-color);
            margin-top: 0;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .container, .service, .info {
            animation: fadeIn 0.5s ease-out forwards;
        }

        .service:nth-child(2) { animation-delay: 0.1s; }
        .service:nth-child(3) { animation-delay: 0.2s; }
        .info { animation-delay: 0.3s; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Belullama Ecosystem</h1>
        
        <div class="services">
            <div class="service">
                <div class="logo-placeholder">O</div>
                <h2>Ollama API</h2>
                <p>Access the Ollama API for advanced AI model interactions.</p>
                <a href="http://${ip_address}:11434" class="button" target="_blank">Open Ollama API</a>
            </div>
            
            <div class="service">
                <div class="logo-placeholder">W</div>
                <h2>Open WebUI</h2>
                <p>User-friendly interface for interacting with AI models.</p>
                <a href="http://${ip_address}:8080" class="button" target="_blank">Open WebUI</a>
            </div>
            
            <div class="service">
                <div class="logo-placeholder">SD</div>
                <h2>Stable Diffusion WebUI</h2>
                <p>Generate and manipulate images using AI.</p>
                <a href="http://${ip_address}:7860" class="button" target="_blank">Open Stable Diffusion</a>
            </div>
        </div>
        
        <div class="info">
            <h3>Additional Information</h3>
            <p><strong>Installation Directory:</strong> $INSTALL_DIR</p>
            <p><strong>IP Address:</strong> ${ip_address}</p>
            <p>For more information and documentation, visit <a href="https://github.com/ai-joe-git/Belullama" target="_blank">Belullama GitHub Repository</a>.</p>
        </div>
    </div>
</body>
</html>
EOL

    print_color "GREEN" "HTML interface generated: $interface_dir/index.html"

    # Create lighttpd configuration file
    cat > "$interface_dir/lighttpd.conf" << EOL
server.document-root = "$interface_dir"
server.port = $port
server.bind = "$ip_address"
mimetype.assign = (
    ".html" => "text/html",
    ".css"  => "text/css",
    ".js"   => "application/javascript"
)
EOL

    # Install lighttpd if not already installed
    install_lighttpd

    # Find lighttpd executable
    local lighttpd_exec=$(find_lighttpd)

    if [ -z "$lighttpd_exec" ]; then
        print_color "RED" "Could not find lighttpd executable. Please ensure it's installed and in your PATH."
        exit 1
    fi

    # Start lighttpd server
    sudo "$lighttpd_exec" -f "$interface_dir/lighttpd.conf" -D &

    print_color "BLUE" "
╔═══════════════════════════════════════════════════════╗
║    Belullama Ecosystem Interface is now served!       ║
╚═══════════════════════════════════════════════════════╝

You can access the Belullama Ecosystem interface at:
http://${ip_address}:${port}

This interface and all the linked services are accessible 
from any device on your local network using the IP address: ${ip_address}
"

    # Attempt to open the HTML file in the default browser on the local machine
    if command_exists xdg-open; then
        xdg-open "http://${ip_address}:${port}"
    elif command_exists open; then
        open "http://${ip_address}:${port}"
    elif command_exists start; then
        start "http://${ip_address}:${port}"
    else
        print_color "YELLOW" "Could not automatically open the interface in a browser. Please open http://${ip_address}:${port} in your web browser."
    fi
}

# Main execution
mkdir -p "$INSTALL_DIR"
generate_and_serve_html_interface

print_color "BLUE" "Setup complete. Enjoy using Belullama!"
This script includes all the necessary functions and the main execution flo