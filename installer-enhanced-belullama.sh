#!/bin/bash

# Belullama Enhanced Installer
# One-line installer that downloads and runs the main installation script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print messages
print_message() {
    echo -e "${CYAN}>>> $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Banner
echo -e "${PURPLE}"
cat << "EOF"
██████╗ ███████╗██╗     ██╗   ██╗██╗     ██╗      █████╗ ███╗   ███╗ █████╗ 
██╔══██╗██╔════╝██║     ██║   ██║██║     ██║     ██╔══██╗████╗ ████║██╔══██╗
██████╔╝█████╗  ██║     ██║   ██║██║     ██║     ███████║██╔████╔██║███████║
██╔══██╗██╔══╝  ██║     ██║   ██║██║     ██║     ██╔══██║██║╚██╔╝██║██╔══██║
██████╔╝███████╗███████╗╚██████╔╝███████╗███████╗██║  ██║██║ ╚═╝ ██║█�[...]
╚═════╝ ╚══════╝╚══════╝ ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚��[...]

                    ███████╗███╗   ██╗██╗  ██╗ █████╗ ███╗   ██╗ ██████╗███████╗██████╗ 
                    ██╔════╝████╗  ██║██║  ██║██╔══██╗████╗  ██║██╔════╝██╔════╝██╔═[...]
                    █████╗  ██╔██╗ ██║███████║███████║██╔██╗ ██║██║     █████╗  ██║  ██║
                    ██╔══╝  ██║╚██╗██║██╔══██║██╔══██║██║╚██╗██║██║     ██╔══╝  ██║  ██�[...]
                    ███████╗██║ ╚████║██║  ██║██║  ██║██║ ╚████║╚██████╗███████╗████[...]
                    ╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═════[...]

EOF
echo -e "${NC}"
echo -e "${CYAN}🚀 Enhanced Installer - One-Command AI Suite${NC}"
echo -e "${CYAN}   Automatic1111 • ComfyUI • Ollama • Open WebUI${NC}"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "Don't run this installer as root. Please run as a normal user."
    exit 1
fi

# Check for required tools
print_message "Checking prerequisites..."

if ! command -v curl &> /dev/null; then
    print_error "curl is required but not installed. Please install curl first."
    exit 1
fi

if ! command -v mktemp &> /dev/null; then
    print_error "mktemp is required but not installed."
    exit 1
fi

print_success "Prerequisites check passed"

# Create a temporary directory
print_message "Creating temporary workspace..."
temp_dir=$(mktemp -d)
cd "$temp_dir"
print_success "Temporary directory created: $temp_dir"

# Download the main installation script
print_message "Downloading Belullama Enhanced installation script..."
if curl -fsSL -o install-enhanced-belullama.sh https://raw.githubusercontent.com/ai-joe-git/belullama/main/install-enhanced-belullama.sh; then
    print_success "Installation script downloaded successfully"
else
    print_error "Failed to download installation script. Please check your internet connection."
    cd ..
    rm -rf "$temp_dir"
    exit 1
fi

# Verify the script was downloaded and is not empty
if [[ ! -s install-enhanced-belullama.sh ]]; then
    print_error "Downloaded script is empty or corrupted."
    cd ..
    rm -rf "$temp_dir"
    exit 1
fi

# Make the script executable
print_message "Making the installation script executable..."
chmod +x install-enhanced-belullama.sh
print_success "Script permissions set"

# Run the installation script
print_message "Starting Belullama Enhanced installation..."
echo -e "${YELLOW}===========================================${NC}"
echo -e "${YELLOW}  Running Main Installation Script...${NC}"
echo -e "${YELLOW}===========================================${NC}"
echo ""

# Execute the main script
if ./install-enhanced-belullama.sh; then
    print_success "Belullama Enhanced installation completed successfully!"
else
    print_error "Installation failed. Please check the logs above for details."
    cd ..
    rm -rf "$temp_dir"
    exit 1
fi

# Clean up
print_message "Cleaning up temporary files..."
cd ..
rm -rf "$temp_dir"
print_success "Cleanup completed"

echo ""
echo -e "${GREEN}🎉 Belullama Enhanced is now ready to use!${NC}"
echo -e "${CYAN}   Visit http://localhost:3000 to get started${NC}"
