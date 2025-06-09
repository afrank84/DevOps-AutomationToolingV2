#!/bin/bash

# === USER CONFIGURATION ===
GITHUB_EMAIL="your_email@example.com"      # Replace with your GitHub email
GIT_USERNAME="Your Full Name"              # Git commit author name
SSH_KEY_FILENAME="id_rsa_github"           # File name for the SSH key (no spaces)
USE_PASSPHRASE=false                       # true = prompt for passphrase, false = no passphrase
# ===========================

# === Derived Paths ===
SSH_DIR="$HOME/.ssh"
SSH_KEY_PATH="$SSH_DIR/$SSH_KEY_FILENAME"

# Ensure .ssh directory exists
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Generate SSH key
if [ "$USE_PASSPHRASE" = true ]; then
    ssh-keygen -t rsa -b 4096 -C "$GITHUB_EMAIL" -f "$SSH_KEY_PATH"
else
    ssh-keygen -t rsa -b 4096 -C "$GITHUB_EMAIL" -f "$SSH_KEY_PATH" -N ""
fi

# Start SSH agent and add the key
eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY_PATH"

# Set global Git config
git config --global user.name "$GIT_USERNAME"
git config --global user.email "$GITHUB_EMAIL"

# Output public key
echo -e "\nYour public SSH key (add this to GitHub):"
echo "------------------------------------------"
cat "$SSH_KEY_PATH.pub"
echo "------------------------------------------"
echo -e "\nAdd your key at: https://github.com/settings/ssh/new"
