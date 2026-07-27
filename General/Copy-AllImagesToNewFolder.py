#!/usr/bin/env python3

import shutil
from pathlib import Path

# ===== CONFIGURE THESE =====
SOURCE_DIR = Path("/path/to/source")
DEST_DIR = Path("/path/to/destination")
# ===========================

IMAGE_EXTENSIONS = {
    ".jpg", ".jpeg", ".png", ".gif", ".bmp",
    ".tif", ".tiff", ".webp", ".svg",
    ".heic", ".heif", ".avif", ".ico"
}

DEST_DIR.mkdir(parents=True, exist_ok=True)

copied = 0
skipped = 0

for file in SOURCE_DIR.rglob("*"):
    if file.is_file() and file.suffix.lower() in IMAGE_EXTENSIONS:
        destination = DEST_DIR / file.name

        # Prevent overwriting files with the same name
        if destination.exists():
            stem = file.stem
            suffix = file.suffix
            counter = 1
            while destination.exists():
                destination = DEST_DIR / f"{stem}_{counter}{suffix}"
                counter += 1

        shutil.copy2(file, destination)
        copied += 1

print(f"Copied {copied} images.")
