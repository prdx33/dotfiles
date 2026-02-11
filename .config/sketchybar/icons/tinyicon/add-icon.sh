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

# ── Scan /Applications for apps ──────────────────────────────────────
# Usage: scan_apps [--all]
#   Default: only unmapped third-party apps
#   --all:   all installed apps (including mapped ones)
scan_apps() {
    local show_all=false
    [[ "${1:-}" == "--all" ]] && show_all=true

    local mapped_bundles
    mapped_bundles=$(get_mapped_bundles)

    local results=()

    for base in /Applications "$HOME/Applications"; do
        [[ -d "$base" ]] || continue
        for app in "$base"/*.app; do
            [[ -d "$app" ]] || continue

            local plist="$app/Contents/Info.plist"
            [[ -f "$plist" ]] || continue

            local bundle_id
            bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$plist" 2>/dev/null) || continue
            [[ -z "$bundle_id" ]] && continue

            # Skip Apple apps
            [[ "$bundle_id" == com.apple.* ]] && continue

            # Skip if already mapped (unless --all)
            if [[ "$show_all" == false ]] && echo "$mapped_bundles" | grep -qFx "$bundle_id"; then
                continue
            fi

            local app_name
            app_name=$(basename "$app" .app)
            local tag=""
            if [[ "$show_all" == true ]] && echo "$mapped_bundles" | grep -qFx "$bundle_id"; then
                tag=" *"
            fi
            results+=("$app_name|$bundle_id|$tag")
        done
    done

    printf '%s\n' "${results[@]}" | sort
}

# ── Derive icon filename from app name ────────────────────────────────
derive_icon_name() {
    local app_name="$1"
    echo "$app_name" | tr '[:upper:]' '[:lower:]' | tr -d ' ' | sed 's/[^a-z0-9]//g'
}

# ── Extract built-in icon from .app bundle ───────────────────────────
extract_app_icon() {
    local bundle_id="$1"

    # Find the .app
    local app_path=""
    for base in /Applications "$HOME/Applications" /System/Applications /System/Applications/Utilities; do
        for app in "$base"/*.app; do
            [[ -d "$app" ]] || continue
            local bid
            bid=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$app/Contents/Info.plist" 2>/dev/null) || continue
            if [[ "$bid" == "$bundle_id" ]]; then
                app_path="$app"
                break 2
            fi
        done
    done

    if [[ -z "$app_path" ]]; then
        echo ""
        return 1
    fi

    # Get .icns path
    local icon_file
    icon_file=$(defaults read "$app_path/Contents/Info" CFBundleIconFile 2>/dev/null)
    [[ -z "$icon_file" ]] && icon_file="AppIcon"
    [[ "$icon_file" != *.icns ]] && icon_file="${icon_file}.icns"
    local icns_path="$app_path/Contents/Resources/$icon_file"

    if [[ ! -f "$icns_path" ]]; then
        echo ""
        return 1
    fi

    # Extract to 512px PNG via sips (high-res source for clean downscale)
    local tmp_dir="/tmp/sketchybar-add-icon"
    mkdir -p "$tmp_dir"
    local tmp_png="$tmp_dir/extracted_512.png"

    sips -s format png --resampleWidth 512 --resampleHeight 512 \
        "$icns_path" --out "$tmp_png" >/dev/null 2>&1

    if [[ ! -f "$tmp_png" ]]; then
        echo ""
        return 1
    fi

    echo "$tmp_png"
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

    while true; do
        # Choose scope
        local scope
        scope=$(gum choose --header "Show:" \
            "Unmapped apps only" \
            "All installed apps") || break

        local scan_flag=""
        [[ "$scope" == "All installed apps" ]] && scan_flag="--all"

        # Scan apps
        gum spin --spinner dot --title "Scanning installed apps..." -- sleep 0.5
        local app_list
        app_list=$(scan_apps $scan_flag)

        if [[ -z "$app_list" ]]; then
            gum style --foreground 10 "All installed apps already have icon mappings."
            break
        fi

        local count
        count=$(echo "$app_list" | wc -l | tr -d ' ')
        gum style --foreground 11 "Found $count apps"
        echo ""

        # Build display lines for gum choose (* = already mapped)
        local display_lines=()
        while IFS='|' read -r app_name bundle_id tag; do
            display_lines+=("${tag:+$tag }$app_name  ($bundle_id)")
        done <<< "$app_list"

        # Let user select an app
        local selected
        selected=$(printf '%s\n' "${display_lines[@]}" | gum choose --header "Select an app:" --height 20) || break

        # Parse selection back to components (strip leading * tag if present)
        local selected_app selected_bundle
        selected_app=$(echo "$selected" | sed 's/^ \* //' | sed 's/  (.*//')
        selected_bundle=$(echo "$selected" | sed 's/.*(\(.*\))/\1/')

        gum style --foreground 14 "Selected: $selected_app ($selected_bundle)"
        echo ""

        # Choose icon source
        local icon_source
        icon_source=$(gum choose --header "Icon source:" \
            "Use app's built-in icon" \
            "Provide a custom PNG") || break

        local src_png
        if [[ "$icon_source" == "Use app's built-in icon" ]]; then
            gum spin --spinner dot --title "Extracting icon from app bundle..." -- sleep 0.2
            src_png=$(extract_app_icon "$selected_bundle")

            if [[ -z "$src_png" || ! -f "$src_png" ]]; then
                gum style --foreground 9 "Error: Could not extract icon from app bundle"
                continue
            fi

            gum style --foreground 10 "Extracted icon from app bundle"
        else
            # Prompt for source PNG
            src_png=$(gum input \
                --header "Path to source .png file (square format):" \
                --placeholder "/path/to/icon.png" \
                --width 80) || break

            # Expand ~ if used
            src_png="${src_png/#\~/$HOME}"

            # Validate source file
            if [[ ! -f "$src_png" ]]; then
                gum style --foreground 9 "Error: File not found: $src_png"
                continue
            fi

            if [[ "${src_png##*.}" != "png" ]]; then
                gum style --foreground 9 "Error: Source file must be a .png"
                continue
            fi
        fi

        # Derive and confirm icon filename
        local default_name
        default_name=$(derive_icon_name "$selected_app")

        local icon_name
        icon_name=$(gum input \
            --header "Icon filename (without .png):" \
            --value "$default_name" \
            --placeholder "appname") || break

        local icon_file="${icon_name}.png"

        # Check if icon file already exists
        if [[ -f "$DEST_24/$icon_file" ]]; then
            gum confirm "Icon $icon_file already exists in 24px/. Overwrite?" || continue
        fi

        echo ""
        gum style --foreground 11 "Processing..."

        # Process the icon
        process_icon "$src_png" "$icon_file"

        # Insert mapping into app_icons.sh (skip if already mapped)
        if ! grep -qF "$selected_bundle)" "$APP_ICONS_SH"; then
            insert_mapping "$selected_bundle" "$icon_file"
        fi

        # Reload sketchybar and refresh workspace icons
        (sketchybar --reload 2>/dev/null; sleep 1; "$DOTFILES_BASE/plugins/aerospace_refresh.sh") &

        # Summary
        echo ""
        gum style --bold --foreground 10 "Done!"
        echo ""
        echo "  App:        $selected_app"
        echo "  Bundle ID:  $selected_bundle"
        echo "  Icon file:  $icon_file"
        echo "  24px:       $DEST_24/$icon_file"
        echo "  dim25:      $DEST_DIM/$icon_file"
        echo ""
        gum style --foreground 8 "SketchyBar reloaded"
        echo ""
    done

    # Cleanup temp files
    rm -rf /tmp/sketchybar-add-icon
}

main "$@"
