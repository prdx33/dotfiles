#!/bin/bash
# add-icon.sh — Interactive tool to add missing app icons to sketchybar
#
# Scans installed apps, finds those without icon mappings, lets you
# add a custom icon with proper 24px + dim25 processing.
#
# Dependencies: gum (brew install gum), magick (brew install imagemagick)
#
# Usage:
#   add-icon.sh          # Interactive mode
#   add-icon.sh --help   # Show this help

set -euo pipefail

# ── Paths ──────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_BASE="$HOME/Dev/dotfiles/.config/sketchybar"
APP_ICONS_SH="$DOTFILES_BASE/plugins/app_icons.sh"
DEST_24="$SCRIPT_DIR/24px"
DEST_DIM="$DEST_24/dim25"

# ── Preflight checks ──────────────────────────────────────────────────
preflight() {
    local missing=()
    command -v gum   >/dev/null 2>&1 || missing+=("gum (brew install gum)")
    command -v magick >/dev/null 2>&1 || missing+=("magick (brew install imagemagick)")

    if [[ ! -f "$APP_ICONS_SH" ]]; then
        echo "Error: app_icons.sh not found at $APP_ICONS_SH" >&2
        exit 1
    fi

    if (( ${#missing[@]} > 0 )); then
        echo "Missing dependencies:" >&2
        printf '  - %s\n' "${missing[@]}" >&2
        exit 1
    fi

    mkdir -p "$DEST_24" "$DEST_DIM"
}

# ── Parse existing bundle IDs from app_icons.sh ───────────────────────
get_mapped_bundles() {
    # Extract bundle IDs from case statement lines like:
    #   com.spotify.client) echo "spotify.png" ;;
    sed -n 's/^[[:space:]]*\([A-Za-z0-9._-]*\)) echo ".*;;$/\1/p' "$APP_ICONS_SH" | sort -u
}

# ── Scan /Applications for third-party apps ───────────────────────────
scan_apps() {
    local mapped_bundles
    mapped_bundles=$(get_mapped_bundles)

    local results=()

    for app in /Applications/*.app; do
        [[ -d "$app" ]] || continue

        local plist="$app/Contents/Info.plist"
        [[ -f "$plist" ]] || continue

        local bundle_id
        bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$plist" 2>/dev/null) || continue
        [[ -z "$bundle_id" ]] && continue

        # Skip Apple apps
        [[ "$bundle_id" == com.apple.* ]] && continue

        # Skip if already mapped
        if echo "$mapped_bundles" | grep -qFx "$bundle_id"; then
            continue
        fi

        local app_name
        app_name=$(basename "$app" .app)
        results+=("$app_name|$bundle_id")
    done

    # Also scan ~/Applications
    if [[ -d "$HOME/Applications" ]]; then
        for app in "$HOME/Applications/"*.app; do
            [[ -d "$app" ]] || continue

            local plist="$app/Contents/Info.plist"
            [[ -f "$plist" ]] || continue

            local bundle_id
            bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$plist" 2>/dev/null) || continue
            [[ -z "$bundle_id" ]] && continue

            [[ "$bundle_id" == com.apple.* ]] && continue

            if echo "$mapped_bundles" | grep -qFx "$bundle_id"; then
                continue
            fi

            local app_name
            app_name=$(basename "$app" .app)
            results+=("$app_name|$bundle_id")
        done
    fi

    printf '%s\n' "${results[@]}" | sort
}

# ── Derive icon filename from app name ────────────────────────────────
derive_icon_name() {
    local app_name="$1"
    echo "$app_name" | tr '[:upper:]' '[:lower:]' | tr -d ' ' | sed 's/[^a-z0-9]//g'
}

# ── Process icon: resize + dim ────────────────────────────────────────
process_icon() {
    local src="$1"
    local icon_file="$2"  # e.g. "myapp.png"

    # Resize to 24x24
    magick "$src" -resize 24x24 -strip "$DEST_24/$icon_file"

    # 25% opacity dim version
    magick "$src" -resize 24x24 -strip -channel A -evaluate Multiply 0.25 +channel "$DEST_DIM/$icon_file"
}

# ── Insert mapping into app_icons.sh ──────────────────────────────────
insert_mapping() {
    local bundle_id="$1"
    local icon_file="$2"

    # Insert before the wildcard catch-all:  *) echo "" ;;
    # Use a temp file for safety
    local tmp
    tmp=$(mktemp)

    local new_line="        ${bundle_id}) echo \"${icon_file}\" ;;"

    awk -v new="$new_line" '
        /^[[:space:]]+\*\)[[:space:]]+echo[[:space:]]+""/ {
            print new
        }
        { print }
    ' "$APP_ICONS_SH" > "$tmp"

    mv "$tmp" "$APP_ICONS_SH"
}

# ── Main ──────────────────────────────────────────────────────────────
main() {
    if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
        echo "add-icon.sh — Add missing app icons to sketchybar"
        echo ""
        echo "Scans installed apps, finds those without icon mappings,"
        echo "and interactively adds a custom icon with 24px + dim processing."
        echo ""
        echo "Dependencies: gum, imagemagick (magick)"
        echo ""
        echo "Usage:"
        echo "  add-icon.sh          Interactive mode"
        echo "  add-icon.sh --help   Show this help"
        exit 0
    fi

    preflight

    gum style --bold --foreground 212 "add-icon — sketchybar icon mapper"
    echo ""

    # Scan for missing apps
    gum spin --spinner dot --title "Scanning installed apps..." -- sleep 0.5
    local missing
    missing=$(scan_apps)

    if [[ -z "$missing" ]]; then
        gum style --foreground 10 "All installed apps already have icon mappings."
        exit 0
    fi

    local count
    count=$(echo "$missing" | wc -l | tr -d ' ')
    gum style --foreground 11 "Found $count apps without icon mappings"
    echo ""

    # Build display lines for gum choose
    local display_lines=()
    while IFS='|' read -r app_name bundle_id; do
        display_lines+=("$app_name  ($bundle_id)")
    done <<< "$missing"

    # Let user select an app
    local selected
    selected=$(printf '%s\n' "${display_lines[@]}" | gum choose --header "Select an app to add an icon for:" --height 20) || {
        echo "Cancelled."
        exit 0
    }

    # Parse selection back to components
    local selected_app selected_bundle
    selected_app=$(echo "$selected" | sed 's/  (.*//')
    selected_bundle=$(echo "$selected" | sed 's/.*(\(.*\))/\1/')

    gum style --foreground 14 "Selected: $selected_app ($selected_bundle)"
    echo ""

    # Prompt for source PNG
    local src_png
    src_png=$(gum input \
        --header "Path to source .png file (square format):" \
        --placeholder "/path/to/icon.png" \
        --width 80) || {
        echo "Cancelled."
        exit 0
    }

    # Expand ~ if used
    src_png="${src_png/#\~/$HOME}"

    # Validate source file
    if [[ ! -f "$src_png" ]]; then
        gum style --foreground 9 "Error: File not found: $src_png"
        exit 1
    fi

    if [[ "${src_png##*.}" != "png" ]]; then
        gum style --foreground 9 "Error: Source file must be a .png"
        exit 1
    fi

    # Derive and confirm icon filename
    local default_name
    default_name=$(derive_icon_name "$selected_app")

    local icon_name
    icon_name=$(gum input \
        --header "Icon filename (without .png):" \
        --value "$default_name" \
        --placeholder "appname") || {
        echo "Cancelled."
        exit 0
    }

    local icon_file="${icon_name}.png"

    # Check if icon file already exists
    if [[ -f "$DEST_24/$icon_file" ]]; then
        gum confirm "Icon $icon_file already exists in 24px/. Overwrite?" || {
            echo "Cancelled."
            exit 0
        }
    fi

    echo ""
    gum style --foreground 11 "Processing..."

    # Process the icon
    process_icon "$src_png" "$icon_file"

    # Insert mapping into app_icons.sh
    insert_mapping "$selected_bundle" "$icon_file"

    # Summary
    echo ""
    gum style --bold --foreground 10 "Done!"
    echo ""
    echo "  App:        $selected_app"
    echo "  Bundle ID:  $selected_bundle"
    echo "  Icon file:  $icon_file"
    echo "  24px:       $DEST_24/$icon_file"
    echo "  dim25:      $DEST_DIM/$icon_file"
    echo "  Mapping:    $selected_bundle -> $icon_file (added to app_icons.sh)"
    echo ""
    gum style --foreground 8 "Restart sketchybar to pick up the new icon:  sketchybar --reload"
}

main "$@"
