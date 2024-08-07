#!/bin/bash

# Define the download location
DOWNLOAD_DIR="$HOME/Downloads"

# Create the directory if it doesn't exist
mkdir -p "$DOWNLOAD_DIR"

# Download the Visual Studio Code .deb package to the Downloads folder
wget -O "$DOWNLOAD_DIR/code_latest_amd64.deb" https://go.microsoft.com/fwlink/?LinkID=760868

# Install the downloaded .deb package
sudo dpkg -i "$DOWNLOAD_DIR/code_latest_amd64.deb"

# Fix any dependency issues
sudo apt-get install -f

# Confirm the installation
if command -v code >/dev/null 2>&1; then
    echo "Visual Studio Code installed successfully."
else
    echo "Failed to install Visual Studio Code."
fi
