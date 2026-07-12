#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./organize_dji_by_month.sh /path/to/videos
#
# Example:
#   ./organize_dji_by_month.sh /mnt/nas/DJI

SOURCE_DIR="${1:-.}"

find "$SOURCE_DIR" -maxdepth 1 -type f | while IFS= read -r file; do
    # Skip hidden files
    [[ "$(basename "$file")" == .* ]] && continue

    # Get year-month from modification time
    month=$(date -r "$file" +"%Y-%m")

    mkdir -p "$SOURCE_DIR/$month"

    mv -n "$file" "$SOURCE_DIR/$month/"
done

echo "Done!"
