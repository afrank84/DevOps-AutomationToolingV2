#!/bin/bash

# Target URL
url="https://trinitybckh.podbean.com/"

# Fetch the webpage content
html=$(curl -s "$url")

# Extract 'Download' links
echo "$html" | grep -oP '<a\s+[^>]*href="([^"]+)"[^>]*>\s*Download\s*</a>' | sed -n 's/.*href="\([^"]*\)".*/\1/p' | while read -r link; do
    # Convert relative URLs to absolute URLs
    if [[ "$link" != http* ]]; then
        link="${url}${link}"
    fi
    echo "$link"
done
