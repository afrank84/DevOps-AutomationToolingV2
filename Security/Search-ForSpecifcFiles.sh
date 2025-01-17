#!/bin/bash

# File containing the list of filenames to search for
FILES_LIST="files.txt"

# File to search in
SEARCH_DOCUMENT="document.txt"

# Output file for results
OUTPUT_FILE="search_results.txt"

# Check if both files exist
if [[ ! -f "$FILES_LIST" || ! -f "$SEARCH_DOCUMENT" ]]; then
    echo "Either $FILES_LIST or $SEARCH_DOCUMENT does not exist. Please check the file paths."
    exit 1
fi

# Clear or create the output file
> "$OUTPUT_FILE"

# Loop through each file in the list and search in the document
while IFS= read -r file; do
    if grep -qF "$file" "$SEARCH_DOCUMENT"; then
        echo "$file: Found" >> "$OUTPUT_FILE"
    else
        echo "$file: Not Found" >> "$OUTPUT_FILE"
    fi
done < "$FILES_LIST"

echo "Search complete. Results saved in $OUTPUT_FILE."
