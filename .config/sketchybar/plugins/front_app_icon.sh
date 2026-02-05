#!/bin/bash

# Update app_icon with the frontmost app's icon
# Uses custom tinyicons when available, falls back to system icons

source "$HOME/.config/sketchybar/plugins/app_icons.sh"

ICON_SCALE=0.75
ICON_WIDTH=20

# Get bundle ID of frontmost app
bundle=$(osascript -e 'tell application "System Events" to get bundle identifier of first application process whose frontmost is true' 2>/dev/null)

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
