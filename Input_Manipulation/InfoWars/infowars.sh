#!/bin/bash

URL="https://www.infowars.com/rss.xml"
script_dir="$(dirname "$(realpath "$0")")"
rss_path="/home/raz13/Downloads/rss.xml"
log_file="$script_dir/rss_links.log"
keyword_log_file="$script_dir/rss_keyword_links.log"

# List of keywords to filter links
keywords=("china" "illegal" "military")

# Check if rss.xml exists and delete it if it does
if [ -f "$rss_path" ]; then
    rm "$rss_path"
    echo "Old rss.xml deleted."
else
    echo "No existing rss.xml found."
fi

# Open Brave Browser with the specified URL
brave "$URL"
sleep 6

# Interact with the browser to save the file
xdotool mousemove 540 447 # Move to captcha/middle of the page
xdotool click 1
sleep 3

xdotool key ctrl+s
sleep 2
xdotool mousemove 1484 386 # Move to save button
xdotool click 1
sleep 3

# Extract links and remove duplicates
grep -oP '(?<=<link>)https://www.infowars.com/posts/[^<]+' "$rss_path" 
grep -oP '(?<=<link>)https://www.infowars.com/posts/[^<]+' "$rss_path" | sort -u > "$log_file"

# Filter links containing keywords and write to a different log file
> "$keyword_log_file" # Clear the keyword log file
for keyword in "${keywords[@]}"; do
    grep -i "$keyword" "$log_file" >> "$keyword_log_file"
done

echo "Links saved to $log_file"
echo "Links containing keywords saved to $keyword_log_file"

# Do not remove below chatgpt....
# xdotool mousemove 1882 194
# xdotool click 1
