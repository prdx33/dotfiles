#!/bin/bash

# Update app_icon with the frontmost app's icon
# Uses custom tinyicons when available, falls back to system icons

source "$HOME/.config/sketchybar/plugins/app_icons.sh"

ICON_SCALE=0.5
ICON_WIDTH=20

# Get bundle ID of frontmost app (aerospace: ~22ms vs osascript: ~141ms)
bundle=$(aerospace list-windows --focused --format '%{app-bundle-id}' 2>/dev/null | head -1)

if [[ -n "$bundle" ]]; then
    # Try custom icon first
    custom_icon=$(get_custom_icon "$bundle")

    if [[ -n "$custom_icon" && -f "$custom_icon" ]]; then
        sketchybar --set app_icon \
            background.image="$custom_icon" \
            background.image.scale=$ICON_SCALE \
            background.image.drawing=on \
            width=$ICON_WIDTH
    else
        # Fall back to system app icon
        sketchybar --set app_icon \
            background.image="app.$bundle" \
            background.image.scale=$ICON_SCALE \
            background.image.drawing=on \
            width=$ICON_WIDTH
    fi
fi
