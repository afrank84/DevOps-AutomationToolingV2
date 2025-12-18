#!/usr/bin/env bash
set -euo pipefail

# Fonts you asked for (Google Fonts families)
FONTS=(
  "Bebas Neue"
  "Oswald"
  "Anton"
  "Barlow"
  "Archivo"
  "League Spartan"
  "Roboto"
)

FONT_DIR="${HOME}/.local/share/fonts"
TMP_DIR="$(mktemp -d)"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "Installing fonts to: $FONT_DIR"
mkdir -p "$FONT_DIR"

download_and_extract() {
  local family="$1"
  local zip_file="$TMP_DIR/$(echo "$family" | tr ' ' '_' | tr -cd '[:alnum:]_').zip"

  # Google Fonts download endpoint (family name must keep spaces; wget will URL-encode)
  local url="https://fonts.google.com/download?family=${family}"

  echo
  echo "==> Downloading: $family"
  if ! wget -qO "$zip_file" "$url"; then
    echo "ERROR: Failed to download '$family' from Google Fonts."
    return 1
  fi

  # Extract only .ttf/.otf files
  echo "==> Extracting: $family"
  local extract_dir="$TMP_DIR/extract_$(echo "$family" | tr ' ' '_' | tr -cd '[:alnum:]_')"
  mkdir -p "$extract_dir"
  unzip -q "$zip_file" -d "$extract_dir"

  # Copy fonts into user font directory
  local count_before count_after
  count_before=$(find "$FONT_DIR" -maxdepth 1 -type f \( -iname '*.ttf' -o -iname '*.otf' \) | wc -l)

  find "$extract_dir" -type f \( -iname '*.ttf' -o -iname '*.otf' \) -print0 \
    | xargs -0 -I{} cp -f "{}" "$FONT_DIR/"

  count_after=$(find "$FONT_DIR" -maxdepth 1 -type f \( -iname '*.ttf' -o -iname '*.otf' \) | wc -l)
  echo "==> Installed files: $((count_after - count_before)) (may overwrite existing)"
}

# Optional: install what Debian/Ubuntu *does* have, but don't fail if missing
echo "==> Attempting apt install for packaged fonts (optional)..."
if command -v apt >/dev/null 2>&1; then
  sudo apt update -qq || true
  sudo apt install -y fonts-bebas-neue fonts-roboto fonts-league-spartan || true
fi

# Manual install from Google Fonts (works everywhere)
for f in "${FONTS[@]}"; do
  download_and_extract "$f"
done

echo
echo "==> Rebuilding font cache..."
fc-cache -f -v >/dev/null

echo
echo "==> Verifying installed fonts (fontconfig names):"
fc-list | grep -E "Bebas|Oswald|Anton|Barlow|Archivo|Spartan|Roboto" || true

echo
echo "Done. Restart Kdenlive to see the new fonts."
