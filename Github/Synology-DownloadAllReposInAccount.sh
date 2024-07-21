#!/bin/bash

# GitHub username
USERNAME="PUT_USERNAME_HERE"
TOKEN="YOUR_PERSONAL_ACCESS_TOKEN"  # If you're using HTTPS with a personal access token

# Directory to store repositories
# Example: "/volume1/homes/TheFrankEmpire/stash/github"
BASE_DIR="/volume1/PATH_TO_FOLDER"

# Create base directory if it doesn't exist
mkdir -p "$BASE_DIR"

# Get a list of all repositories for the user
REPOS=$(curl -s -H "Authorization: token $TOKEN" "https://api.github.com/users/$USERNAME/repos?per_page=100" | grep -o 'git@[^"]*')

# Loop through each repository and pull the latest updates
for REPO in $REPOS; do
  REPO_NAME=$(basename "$REPO" .git)
  REPO_DIR="$BASE_DIR/$REPO_NAME"

  if [ -d "$REPO_DIR" ]; then
    cd "$REPO_DIR"
    git pull origin main
  else
    git clone "$REPO" "$REPO_DIR"
  fi
done
