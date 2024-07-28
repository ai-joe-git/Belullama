#!/bin/bash

# Function to print messages
print_message() {
    echo ">>> $1"
}

# Create a temporary directory
temp_dir=$(mktemp -d)
cd "$temp_dir"

# Download the installation script
print_message "Downloading Belullama installation script..."
curl -s -O https://raw.githubusercontent.com/ai-joe-git/Belullama/main/setup_belullama_gpu.sh

# Make the script executable
print_message "Making the installation script executable..."
chmod +x setup_belullama_gpu.sh

# Run the installation script
print_message "Running the Belullama installation script..."
./setup_belullama_gpu.sh

# Clean up
cd ..
rm -rf "$temp_dir"
