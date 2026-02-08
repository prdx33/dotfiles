#!/bin/bash
# Generate 24px + dim25 icons for macOS built-in apps
# Uses sips (macOS) for .icns extraction, magick (ImageMagick) for resize + dim
#
# Usage: ./generate-macos-icons.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST="$SCRIPT_DIR/24px"
DIM="$DEST/dim25"
TMP="/tmp/sketchybar-icons"

mkdir -p "$DEST" "$DIM" "$TMP"

# Map: bundle_id|icon_name|app_path (app_path optional, auto-detected if empty)
APPS="
com.apple.mail|mail
com.apple.Music|music
com.apple.Notes|notes
com.apple.Maps|maps
com.apple.FaceTime|facetime
com.apple.Preview|preview
com.apple.Terminal|terminal
com.apple.systempreferences|systemsettings
com.apple.AppStore|appstore
com.apple.AddressBook|contacts
com.apple.reminders|reminders
com.apple.news|news
com.apple.stocks|stocks
com.apple.podcasts|podcasts
com.apple.TV|tv
com.apple.iBooksX|books
com.apple.freeform|freeform
com.apple.Home|home
com.apple.weather|weather
com.apple.shortcuts|shortcuts
com.apple.calculator|calculator
com.apple.clock|clock
com.apple.ActivityMonitor|activitymonitor
com.apple.QuickTimePlayerX|quicktime
com.apple.VoiceMemos|voicememos
com.apple.findmy|findmy
com.apple.Passwords|passwords
com.apple.journal|journal
com.apple.keynote|keynote
com.apple.iWork.Numbers|numbers
com.apple.iWork.Pages|pages
"

find_app_path() {
    local bundle_id="$1"
    # Try common locations
    for base in "/Applications" "/System/Applications" "/System/Applications/Utilities"; do
        for app in "$base"/*.app; do
            bid=$(defaults read "$app/Contents/Info" CFBundleIdentifier 2>/dev/null)
            [[ "$bid" == "$bundle_id" ]] && echo "$app" && return
        done
    done
}

get_icns_path() {
    local app_path="$1"
    local icon_file
    icon_file=$(defaults read "$app_path/Contents/Info" CFBundleIconFile 2>/dev/null)
    [[ -z "$icon_file" ]] && icon_file="AppIcon"
    [[ "$icon_file" != *.icns ]] && icon_file="${icon_file}.icns"
    local full_path="$app_path/Contents/Resources/$icon_file"
    [[ -f "$full_path" ]] && echo "$full_path"
}

count=0
skipped=0

echo "$APPS" | while IFS='|' read -r bundle_id name; do
    [[ -z "$bundle_id" ]] && continue

    # Skip if already exists
    if [[ -f "$DEST/$name.png" && -f "$DIM/$name.png" ]]; then
        echo "  SKIP: $name (already exists)"
        skipped=$((skipped + 1))
        continue
    fi

    # Find app
    app_path=$(find_app_path "$bundle_id")
    if [[ -z "$app_path" ]]; then
        echo "  MISS: $name ($bundle_id) - app not found"
        continue
    fi

    # Get .icns path
    icns_path=$(get_icns_path "$app_path")
    if [[ -z "$icns_path" ]]; then
        echo "  MISS: $name - no .icns found in $app_path"
        continue
    fi

    # Step 1: sips extracts from .icns at 512px (highest quality source)
    sips -s format png --resampleWidth 512 --resampleHeight 512 \
        "$icns_path" --out "$TMP/${name}_512.png" >/dev/null 2>&1

    if [[ ! -f "$TMP/${name}_512.png" ]]; then
        echo "  FAIL: $name - sips extraction failed"
        continue
    fi

    # Step 2: magick resizes to 24px
    magick "$TMP/${name}_512.png" -resize 24x24 -strip "$DEST/$name.png" 2>/dev/null

    # Step 3: magick creates 25% opacity dim version
    magick "$TMP/${name}_512.png" -resize 24x24 -strip \
        -channel A -evaluate Multiply 0.25 +channel "$DIM/$name.png" 2>/dev/null

    if [[ -f "$DEST/$name.png" && -f "$DIM/$name.png" ]]; then
        echo "    OK: $name ($bundle_id)"
        count=$((count + 1))
    else
        echo "  FAIL: $name - magick conversion failed"
    fi
done

# Cleanup
rm -rf "$TMP"

echo ""
echo "Done. Check $DEST/ and $DIM/"
