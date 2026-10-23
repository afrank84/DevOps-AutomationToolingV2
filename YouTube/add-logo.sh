#!/usr/bin/env bash

# Must Run Before:
# sudo apt install imagemagick

set -euo pipefail

mkdir -p output

for image in *.jpg *.jpeg *.png *.webp; do
  [[ -f "$image" ]] || continue
  [[ "$image" == "logo.png" ]] && continue

  width=$(identify -format "%w" "$image")
  logo_width=$((width * 15 / 100))
  margin=$((width * 2 / 100))

  convert "$image" \
    \( logo.png -resize "${logo_width}x" \) \
    -gravity southeast \
    -geometry "+${margin}+${margin}" \
    -compose over -composite \
    "output/${image%.*}.png"

  echo "Processed: $image"
done

echo "Finished! Images saved to ./output/"
