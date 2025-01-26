
#!/bin/bash

install_brave_browser() {
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
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list

    # Update package lists
    echo "Updating package lists..."
    sudo apt update

    # Install Brave Browser
    echo "Installing Brave Browser..."
    sudo apt install -y brave-browser

    echo "Brave Browser installation completed."
}

# Call the function
install_brave_browser
