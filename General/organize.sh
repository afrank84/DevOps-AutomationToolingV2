#!/bin/bash

# Default source folder (Downloads)
SOURCE="$HOME/Downloads"

# Target stock folders
DOCS_DIR="$HOME/Documents"
PHOTOS_DIR="$HOME/Pictures"
MOVIES_DIR="$HOME/Movies"

# File extensions
doc_exts=("pdf" "doc" "docx" "txt" "xls" "xlsx" "ppt" "pptx" "pages" "numbers" "key")
photo_exts=("jpg" "jpeg" "png" "gif" "bmp" "tiff" "heic" "webp" "raw")
movie_exts=("mp4" "mkv" "mov" "avi" "wmv" "flv" "webm")

echo "Recursively organizing files in $SOURCE..."

# Move documents
for ext in "${doc_exts[@]}"; do
  find "$SOURCE" -type f -iname "*.${ext}" -exec mv -v {} "$DOCS_DIR" \;
done

# Move photos
for ext in "${photo_exts[@]}"; do
  find "$SOURCE" -type f -iname "*.${ext}" -exec mv -v {} "$PHOTOS_DIR" \;
done

# Move movies
for ext in "${movie_exts[@]}"; do
  find "$SOURCE" -type f -iname "*.${ext}" -exec mv -v {} "$MOVIES_DIR" \;
done

echo "✅ Done. All matching files moved to stock folders."
