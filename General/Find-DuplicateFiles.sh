#!/usr/bin/env bash

# Find files with duplicate filenames recursively.
# Usage:
#   ./find_duplicate_names.sh
#   ./find_duplicate_names.sh /path/to/search

SEARCH_DIR="${1:-.}"

if [[ ! -d "$SEARCH_DIR" ]]; then
    echo "Error: Directory does not exist: $SEARCH_DIR" >&2
    exit 1
fi

declare -A FILE_COUNTS
declare -A FILE_LOCATIONS

while IFS= read -r -d '' FILE; do
    FILE_NAME="$(basename "$FILE")"

    ((FILE_COUNTS["$FILE_NAME"]++))

    if [[ -n "${FILE_LOCATIONS[$FILE_NAME]:-}" ]]; then
        FILE_LOCATIONS["$FILE_NAME"]+=$'\n'
    fi

    FILE_LOCATIONS["$FILE_NAME"]+="$FILE"
done < <(find "$SEARCH_DIR" -type f -print0 2>/dev/null)

DUPLICATES_FOUND=0

for FILE_NAME in "${!FILE_COUNTS[@]}"; do
    if (( FILE_COUNTS["$FILE_NAME"] > 1 )); then
        DUPLICATES_FOUND=1

        echo
        echo "============================================================"
        echo "Duplicate filename: $FILE_NAME"
        echo "Number found: ${FILE_COUNTS[$FILE_NAME]}"
        echo "Locations:"
        printf '%s\n' "${FILE_LOCATIONS[$FILE_NAME]}"
    fi
done

if (( DUPLICATES_FOUND == 0 )); then
    echo "No duplicate filenames found in: $SEARCH_DIR"
fi
