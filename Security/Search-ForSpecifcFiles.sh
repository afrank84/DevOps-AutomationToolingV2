#!/bin/bash

# File containing the list of filenames to search for
FILES_LIST="files.txt"

# Output file for results
OUTPUT_FILE="Specific_Files.txt"

# Locate the USB drive
USB_DRIVE=$(lsblk -o MOUNTPOINT,RM | grep ' 1$' | awk '{print $1}' | head -n 1)

if [[ -z "$USB_DRIVE" || ! -d "$USB_DRIVE" ]]; then
    echo "No USB drive detected. Please ensure the USB is plugged in and mounted."
    exit 1
fi

echo "USB drive found at: $USB_DRIVE"

# Find all results.txt files on the USB drive
RESULT_FILES=$(find "$USB_DRIVE" -type f -name "results.txt")

if [[ -z "$RESULT_FILES" ]]; then
    echo "No results.txt files found on the USB drive."
    exit 1
fi

# Clear or create the output file
> "$OUTPUT_FILE"

# Check if the list of files exists
if [[ ! -f "$FILES_LIST" ]]; then
    echo "File list ($FILES_LIST) not found. Please ensure it exists."
    exit 1
fi

# Loop through each results.txt file
for RESULT_FILE in $RESULT_FILES; do
    echo "Processing $RESULT_FILE..."

    # Loop through each file in the list and search in the current results.txt file
    while IFS= read -r file; do
        if grep -qF "$file" "$RESULT_FILE"; then
            echo "$file: Found in $RESULT_FILE" >> "$OUTPUT_FILE"
        else
            echo "$file: Not Found in $RESULT_FILE" >> "$OUTPUT_FILE"
        fi
    done < "$FILES_LIST"
done

echo "Search complete. Results saved in $OUTPUT_FILE."
