#!/bin/bash

CUSTOM_ICONS="$HOME/.config/sketchybar/icons/tinyicon/24px"
CUSTOM_ICONS_DIM="$HOME/.config/sketchybar/icons/tinyicon/24px/dim50"

# Map bundle IDs to custom icon filename
get_icon_name() {
    local bundle="$1"
    case "$bundle" in
        com.mitchellh.ghostty) echo "ghostty.png" ;;
        com.adobe.illustrator) echo "illustrator.png" ;;
        com.adobe.Photoshop) echo "photoshop.png" ;;
        com.spotify.client) echo "spotify.png" ;;
        md.obsidian) echo "obsidian.png" ;;
        com.tinyspeck.slackmacgap) echo "slack.png" ;;
        com.microsoft.VSCode) echo "vscode.png" ;;
        dev.warp.Warp-Stable) echo "warp.png" ;;
        com.raycast.macos) echo "raycast.png" ;;
        net.whatsapp.WhatsApp) echo "whatsapp.png" ;;
        com.openai.chat) echo "chatgpt.png" ;;
        com.anthropic.claudefordesktop) echo "claude.png" ;;
        com.apple.finder) echo "finder.png" ;;
        com.apple.TextEdit) echo "textedit.png" ;;
        com.readdle.spark) echo "spark.png" ;;
        com.asiafu.Bloom) echo "bloom.png" ;;
        org.mozilla.firefox) echo "firefox.png" ;;
        *) echo "" ;;
    esac
}

# Get icon path with appropriate dimming
# Usage: get_custom_icon_dimmed <bundle_id> <state>
# State: focused | unfocused
get_custom_icon_dimmed() {
    local bundle="$1"
    local state="$2"
    local icon_name=$(get_icon_name "$bundle")

    [[ -z "$icon_name" ]] && echo "" && return

    case "$state" in
        focused)
            echo "$CUSTOM_ICONS/$icon_name" ;;
        *)
            echo "$CUSTOM_ICONS_DIM/$icon_name" ;;
    esac
}

# Legacy function for compatibility
get_custom_icon() {
    local bundle="$1"
    local icon_name=$(get_icon_name "$bundle")
    [[ -n "$icon_name" ]] && echo "$CUSTOM_ICONS/$icon_name" || echo ""
}

# Get list of apps on a workspace (unique, space-separated bundle IDs)
# Uses aerospace's native bundle ID output - no mdls lookup needed
get_workspace_apps() {
    local workspace="$1"
    aerospace list-windows --workspace "$workspace" --format "%{app-bundle-id}" 2>/dev/null | sort -u | tr '\n' ' ' | xargs
}
