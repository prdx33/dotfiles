#!/bin/bash

# Refresh all workspace items
# 2 states:
# - Visible on monitor: 100%
# - Has apps but not visible: 50%

CONFIG_DIR="$HOME/.config/sketchybar"
source "$CONFIG_DIR/colours.sh" 2>/dev/null || exit 0
source "$CONFIG_DIR/plugins/app_icons.sh" 2>/dev/null

FONT="Iosevka Extended"
MONO_FONT="Iosevka Extended"
MAX_ICONS=4
FONT_SIZE=13.0
ICON_SCALE=0.5
ICON_WIDTH=16
ICON_GAP=3
WS_ICON_GAP=5
WORKSPACE_GAP=14

# Workspaces 1-9, 0, then 10
WORKSPACES="1 2 3 4 5 6 7 8 9 0 10"

# Get visible (active) workspace for each monitor
m1_ws=$(aerospace list-workspaces --monitor 1 --visible 2>/dev/null | xargs)
m2_ws=$(aerospace list-workspaces --monitor 2 --visible 2>/dev/null | xargs)

# Get focused workspace
focused_ws=$(aerospace list-workspaces --focused 2>/dev/null | xargs)

for space_id in $WORKSPACES; do
    # Get bundle IDs for apps on this workspace
    bundle_ids=$(get_workspace_apps "$space_id")
    IFS=' ' read -ra BUNDLES <<< "$bundle_ids"
    num_apps=${#BUNDLES[@]}

    # Determine state - Heavy only for focused, Regular for everything else
    if [[ "$space_id" == "$focused_ws" ]]; then
        # Focused workspace - Heavy + 100%
        icon_font="$MONO_FONT:Heavy:$FONT_SIZE"
        icon_color=$WS_FOCUSED
        icon_state="focused"
    elif [[ "$space_id" == "$m1_ws" || "$space_id" == "$m2_ws" ]]; then
        # Visible but not focused - Regular + 100%
        icon_font="$MONO_FONT:Regular:$FONT_SIZE"
        icon_color=$WS_FOCUSED
        icon_state="unfocused"
    else
        # Hidden/inactive - Regular + 50%
        icon_font="$MONO_FONT:Regular:$FONT_SIZE"
        icon_color=$WS_UNFOCUSED
        icon_state="unfocused"
    fi

    # Update workspace number - hide if empty and not active
    if [[ $num_apps -eq 0 && "$space_id" != "$focused_ws" && "$space_id" != "$m1_ws" && "$space_id" != "$m2_ws" ]]; then
        sketchybar --set space.$space_id \
            icon.drawing=off \
            icon.padding_left=0 \
            icon.padding_right=0
    else
        sketchybar --set space.$space_id \
            icon.drawing=on \
            icon.font="$icon_font" \
            icon.color="$icon_color" \
            icon.padding_left=$WORKSPACE_GAP \
            icon.padding_right=$WS_ICON_GAP
    fi

    # Update icon slots - show for all workspaces with apps
    for i in $(seq 0 $((MAX_ICONS - 1))); do
        item_name="space.$space_id.icon.$i"

        if [[ $i -lt $num_apps ]]; then
            bundle="${BUNDLES[$i]}"
            custom_icon=$(get_custom_icon_dimmed "$bundle" "$icon_state")
            if [[ -n "$custom_icon" && -f "$custom_icon" ]]; then
                # Custom icon with pre-rendered dimming
                sketchybar --set "$item_name" \
                    icon.drawing=off \
                    background.image="$custom_icon" \
                    background.image.scale=$ICON_SCALE \
                    background.image.drawing=on \
                    width=$(($ICON_WIDTH + $ICON_GAP))
            else
                # Fallback to macOS system app icon - dim if unfocused
                if [[ "$icon_state" == "focused" ]]; then
                    img_color="0xffffffff"
                else
                    img_color="0x80ffffff"
                fi
                sketchybar --set "$item_name" \
                    icon.drawing=off \
                    background.image="app.$bundle" \
                    background.image.scale=$ICON_SCALE \
                    background.image.color="$img_color" \
                    background.image.drawing=on \
                    width=$(($ICON_WIDTH + $ICON_GAP))
            fi
        else
            sketchybar --set "$item_name" \
                icon.drawing=off \
                background.image.drawing=off \
                width=0
        fi
    done
done

# Update JankyBorders colour based on focused window layout
"$CONFIG_DIR/plugins/borders.sh" 2>/dev/null &
