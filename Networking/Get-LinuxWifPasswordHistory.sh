#!/bin/bash

# This script extracts previously used Wi-Fi passwords from NetworkManager configuration files.

# Directory containing the Wi-Fi configuration files
CONFIG_DIR="/etc/NetworkManager/system-connections/"

# Check if the directory exists
if [ ! -d "$CONFIG_DIR" ]; then
    echo "Directory $CONFIG_DIR does not exist."
    exit 1
fi

# Loop through each configuration file in the directory
for config_file in "$CONFIG_DIR"/*; do
    # Extract the Wi-Fi SSID (name)
    ssid=$(grep -oP '(?<=^ssid=).*' "$config_file")

    # Extract the Wi-Fi password
    psk=$(grep -oP '(?<=^psk=).*' "$config_file")

    # Check if both SSID and password were found
    if [ -n "$ssid" ] && [ -n "$psk" ]; then
        echo "SSID: $ssid"
        echo "Password: $psk"
        echo "------------------"
    fi
done
