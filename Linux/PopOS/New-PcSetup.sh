#!/bin/bash

install_brave_browser() {
    echo "Checking if Brave Browser is already installed..."
    if dpkg-query -l | grep -q brave-browser; then
        echo "Brave Browser is already installed."
        return 0
    fi

    echo "Installing Brave Browser..."
    # Install curl if not already installed
    if ! command -v curl &> /dev/null; then
        echo "Installing curl..."
        sudo apt update
        sudo apt install -y curl
    else
        echo "curl is already installed."
    fi

    # Add Brave's GPG key
    echo "Adding Brave's GPG key..."
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

    # Add Brave's repository
    echo "Adding Brave's repository..."
    if ! grep -q "brave-browser-apt-release.s3.brave.com" /etc/apt/sources.list.d/brave-browser-release.list 2>/dev/null; then
        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
    else
        echo "Brave repository is already added."
    fi

    # Update package lists and install Brave Browser
    sudo apt update
    sudo apt install -y brave-browser
    echo "Brave Browser installation completed."
}

install_vscode() {
    echo "Checking if Visual Studio Code is already installed..."
    if dpkg-query -l | grep -q code; then
        echo "Visual Studio Code is already installed."
        return 0
    fi

    echo "Installing Visual Studio Code..."
    # Install curl if not already installed
    if ! command -v curl &> /dev/null; then
        echo "Installing curl..."
        sudo apt update
        sudo apt install -y curl
    else
        echo "curl is already installed."
    fi

    # Add Microsoft's GPG key
    echo "Adding Microsoft's GPG key..."
    sudo curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/vscode-archive-keyring.gpg > /dev/null

    # Add Visual Studio Code repository
    echo "Adding Visual Studio Code repository..."
    if ! grep -q "packages.microsoft.com/repos/code" /etc/apt/sources.list.d/vscode.list 2>/dev/null; then
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/vscode-archive-keyring.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
    else
        echo "Visual Studio Code repository is already added."
    fi

    # Update package lists and install Visual Studio Code
    sudo apt update
    sudo apt install -y code
    echo "Visual Studio Code installation completed."
}

# Main script logic
echo "Choose an option:"
echo "1. Install Brave Browser"
echo "2. Install Visual Studio Code"
echo "3. Install Both"
read -p "Enter your choice (1/2/3): " choice

case $choice in
    1)
        install_brave_browser
        ;;
    2)
        install_vscode
        ;;
    3)
        install_brave_browser
        install_vscode
        ;;
    *)
        echo "Invalid choice. Exiting."
        ;;
esac
