#!/bin/bash
# Process tinyicon artboard PNGs for sketchybar use
# Resizes to 24px and creates 50% opacity dim version
#
# Usage:
#   process-icon.sh <artboard-file> <app-name>
#   process-icon.sh "Artboard 35.png" discord
#
# Batch:
#   process-icon.sh --batch mapping.txt
#   (mapping.txt format: "Artboard 35.png|discord")

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/500px"
DEST="$SCRIPT_DIR/24px"
DIM="$DEST/dim25"

mkdir -p "$DIM"

process_one() {
    local artboard="$1"
    local name="$2"
    local src_file="$SRC/$artboard"

    # Ensure .png extension
    [[ "$name" != *.png ]] && name="${name}.png"

    if [[ ! -f "$src_file" ]]; then
        echo "MISSING: $src_file"
        return 1
    fi

    magick "$src_file" -resize 24x24 -strip "$DEST/$name"
    magick "$src_file" -resize 24x24 -strip -channel A -evaluate Multiply 0.25 +channel "$DIM/$name"
    echo "OK: $artboard -> $name (24px + dim25)"
}

if [[ "$1" == "--batch" ]]; then
    if [[ ! -f "$2" ]]; then
        echo "Usage: $0 --batch <mapping-file>"
        echo "Format: Artboard N.png|appname"
        exit 1
    fi
    while IFS='|' read -r artboard name; do
        [[ -z "$artboard" || "$artboard" == \#* ]] && continue
        process_one "$artboard" "$name"
    done < "$2"
elif [[ -n "$1" && -n "$2" ]]; then
    process_one "$1" "$2"
else
    echo "Usage:"
    echo "  $0 <artboard-file> <app-name>"
    echo "  $0 \"Artboard 35.png\" discord"
    echo ""
    echo "  $0 --batch <mapping-file>"
    echo "  (format: Artboard N.png|appname)"
fi
