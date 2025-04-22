#!/bin/bash

set -e  # Exit on error

echo "=== BeeBEEP Reinstallation Script ==="

# Step 1: Uninstall if installed
if dpkg -l | grep -q beebeep; then
    echo "Uninstalling existing BeeBEEP..."
    sudo apt remove --purge -y beebeep
else
    echo "BeeBEEP not found. Continuing with installation."
fi

# Step 2: Remove old config if it exists
CONFIG_DIR="$HOME/.config/BeeBEEP"
if [ -d "$CONFIG_DIR" ]; then
    echo "Removing existing BeeBEEP config at $CONFIG_DIR..."
    rm -rf "$CONFIG_DIR"
else
    echo "No existing BeeBEEP config found."
fi

# Step 3: Download latest .deb from SourceForge
cd ~/Downloads || exit

DEB_URL="https://sourceforge.net/projects/beebeep/files/Linux/beebeep_5.8.6_amd64.deb/download"

echo "Downloading BeeBEEP from $DEB_URL..."
wget -q --show-progress "$DEB_URL" -O beebeep_latest.deb

# Step 4: Install
echo "Installing BeeBEEP..."
sudo apt install -y ./beebeep_latest.deb

echo "✅ BeeBEEP reinstallation complete."
