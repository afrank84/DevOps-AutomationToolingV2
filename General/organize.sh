#!/bin/bash

# Default source folder (Downloads)
SOURCE="$HOME/Downloads"

# Target stock folders
DOCS_DIR="$HOME/Documents"
PHOTOS_DIR="$HOME/Pictures"

# File extensions
doc_exts=("pdf" "doc" "docx" "txt" "xls" "xlsx" "ppt" "pptx" "pages" "numbers" "key")
photo_exts=("jpg" "jpeg" "png" "gif" "bmp" "tiff" "heic" "webp" "raw")

echo "Organizing files in $SOURCE..."

# Move documents
for ext in "${doc_exts[@]}"; do
  find "$SOURCE" -maxdepth 1 -type f -iname "*.${ext}" -exec mv -v {} "$DOCS_DIR" \;
done

# Move photos
for ext in "${photo_exts[@]}"; do
  find "$SOURCE" -maxdepth 1 -type f -iname "*.${ext}" -exec mv -v {} "$PHOTOS_DIR" \;
done

echo "✅ Done. Documents moved to ~/Documents, Photos to ~/Pictures."
