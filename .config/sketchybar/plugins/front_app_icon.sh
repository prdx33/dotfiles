#!/bin/bash

# Update app_icon with the frontmost app's icon
# Uses same settings as workspace app icons

ICON_SCALE=0.5
ICON_WIDTH=24

# Get bundle ID of frontmost app
bundle=$(osascript -e 'tell application "System Events" to get bundle identifier of first application process whose frontmost is true' 2>/dev/null)

if [[ -n "$bundle" ]]; then
    sketchybar --set app_icon \
        background.image="app.$bundle" \
        background.image.scale=$ICON_SCALE \
        background.image.drawing=on \
        width=$ICON_WIDTH
fi
