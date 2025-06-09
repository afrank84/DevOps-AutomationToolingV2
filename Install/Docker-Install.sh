#!/bin/bash

set -e

# === Variables ===
DOCKER_GPG_PATH="/etc/apt/keyrings/docker.gpg"
DOCKER_LIST="/etc/apt/sources.list.d/docker.list"

echo "Updating system and installing prerequisites..."
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

echo "Adding Docker GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o "$DOCKER_GPG_PATH"

echo "Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=$DOCKER_GPG_PATH] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee "$DOCKER_LIST" > /dev/null

echo "Updating package index..."
sudo apt update

echo "Installing Docker Engine and tools..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Adding user '$USER' to docker group (to allow running without sudo)..."
sudo usermod -aG docker "$USER"

echo "Docker installation complete."
echo "You may need to log out and back in for 'docker' to work without sudo."

echo "Running test container..."
newgrp docker << END
docker run --rm hello-world
END
