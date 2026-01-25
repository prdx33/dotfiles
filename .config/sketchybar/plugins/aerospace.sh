#!/bin/bash

# AeroSpace workspace plugin - single workspace update

source "$CONFIG_DIR/colours.sh"
source "$CONFIG_DIR/plugins/app_icons.sh"

FONT="Iosevka Extended"
MONO_FONT="Iosevka Extended"
MAX_ICONS=4
FONT_SIZE=17.0
ICON_SCALE=0.38
ICON_WIDTH=16
WORKSPACE_GAP=14

space_id="$1"

# Get visible (active) workspace for each monitor
m1_ws=$(aerospace list-workspaces --monitor 1 --visible 2>/dev/null | xargs)
m2_ws=$(aerospace list-workspaces --monitor 2 --visible 2>/dev/null | xargs)

# Get focused workspace
focused_ws=$(aerospace list-workspaces --focused 2>/dev/null | xargs)

# Get bundle IDs for apps on this workspace
bundle_ids=$(get_workspace_apps "$space_id")
IFS=' ' read -ra BUNDLES <<< "$bundle_ids"
num_apps=${#BUNDLES[@]}

# Determine state - all use Bold, opacity varies
icon_font="$MONO_FONT:Bold:$FONT_SIZE"

if [[ "$space_id" == "$focused_ws" ]]; then
    # Focused - 100%
    icon_color=$WS_FOCUSED
elif [[ "$space_id" == "$m1_ws" || "$space_id" == "$m2_ws" ]]; then
    # Visible on monitor - 80%
    icon_color=$WS_UNFOCUSED
else
    # Non-active with apps - 50%
    icon_color=$WS_INACTIVE
fi

# Tiling mode override - mint green (floating is default)
if [[ -f "$HOME/.cache/aerospace/tiling-mode-$space_id" ]]; then
    icon_color=$WS_TILING
fi

# Update workspace number
sketchybar --set space.$space_id \
    icon.font="$icon_font" \
    icon.color="$icon_color" \
    icon.padding_left=$WORKSPACE_GAP \
    icon.padding_right=3

# Update icon slots - show for all workspaces with apps
for i in $(seq 0 $((MAX_ICONS - 1))); do
    item_name="space.$space_id.icon.$i"

    if [[ $i -lt $num_apps ]]; then
        bundle="${BUNDLES[$i]}"
        custom_icon=$(get_custom_icon "$bundle")
        if [[ -n "$custom_icon" && -f "$custom_icon" ]]; then
            sketchybar --set "$item_name" \
                background.image="$custom_icon" \
                background.image.scale=0.5 \
                background.image.drawing=on \
                width=$ICON_WIDTH
        else
            sketchybar --set "$item_name" \
                background.image="app.$bundle" \
                background.image.scale=$ICON_SCALE \
                background.image.drawing=on \
                width=$ICON_WIDTH
        fi
    else
        sketchybar --set "$item_name" \
            background.image.drawing=off \
            width=0
    fi
done

# Update app name colours based on focus
if [[ "$focused_ws" == "$m1_ws" ]]; then
    sketchybar --set app_m1 label.color=$WS_FOCUSED
    sketchybar --set app_m2 label.color=$WS_UNFOCUSED
else
    sketchybar --set app_m1 label.color=$WS_UNFOCUSED
    sketchybar --set app_m2 label.color=$WS_FOCUSED
fi
