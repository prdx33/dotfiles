#!/bin/bash

# Refresh all workspace items
# 2 states:
# - Focused workspace: 100%
# - Everything else: 50%

# Prevent concurrent runs (use mkdir for atomic lock on macOS)
LOCKDIR="/tmp/sketchybar_aerospace_refresh.lock"
if ! mkdir "$LOCKDIR" 2>/dev/null; then
    # Check if lock is stale (older than 5 seconds)
    if [[ -d "$LOCKDIR" ]] && [[ $(($(date +%s) - $(stat -f%m "$LOCKDIR" 2>/dev/null || echo 0))) -gt 5 ]]; then
        rm -rf "$LOCKDIR"
        mkdir "$LOCKDIR" 2>/dev/null || exit 0
    else
        exit 0
    fi
fi
trap "rm -rf '$LOCKDIR'" EXIT

CONFIG_DIR="$HOME/.config/sketchybar"
source "$CONFIG_DIR/colours.sh" 2>/dev/null || exit 0
source "$CONFIG_DIR/plugins/app_icons.sh" 2>/dev/null
source "$CONFIG_DIR/plugins/icon_map.sh" 2>/dev/null

APP_FONT="sketchybar-app-font:Regular:14.0"

FONT="Iosevka Extended"
MONO_FONT="Iosevka Extended"
MAX_ICONS=4
FONT_SIZE=17.0
ICON_SCALE=0.5
ICON_WIDTH=16
ICON_GAP=3
WS_ICON_GAP=8
WORKSPACE_GAP=20

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

    # Determine state - all use Bold, opacity varies
    # Active on monitor = 100% white, others with apps = 50% white
    icon_font="$MONO_FONT:Bold:$FONT_SIZE"

    if [[ "$space_id" == "$focused_ws" || "$space_id" == "$m1_ws" || "$space_id" == "$m2_ws" ]]; then
        # Active on any monitor - 100%
        icon_color=$WS_FOCUSED
        icon_state="focused"
    else
        # Everything else - 50%
        icon_color=$WS_UNFOCUSED
        icon_state="unfocused"
    fi

    # No colour override - all white

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
                # Fallback to app font with color-based dimming
                app_name=$(aerospace list-windows --all --format "%{app-bundle-id}|%{app-name}" 2>/dev/null | grep "^$bundle|" | cut -d'|' -f2 | head -1)
                __icon_map "$app_name"
                if [[ -n "$icon_result" ]]; then
                    sketchybar --set "$item_name" \
                        background.image.drawing=off \
                        icon="$icon_result" \
                        icon.font="$APP_FONT" \
                        icon.color="$icon_color" \
                        icon.drawing=on \
                        width=$(($ICON_WIDTH + $ICON_GAP))
                else
                    # Last resort: macOS app icon (no dimming)
                    sketchybar --set "$item_name" \
                        icon.drawing=off \
                        background.image="app.$bundle" \
                        background.image.scale=$ICON_SCALE \
                        background.image.drawing=on \
                        width=$(($ICON_WIDTH + $ICON_GAP))
                fi
            fi
        else
            sketchybar --set "$item_name" \
                icon.drawing=off \
                background.image.drawing=off \
                width=0
        fi
    done
done

# Update app name colours based on focus
if [[ "$focused_ws" == "$m1_ws" ]]; then
    sketchybar --set app_m1 label.color=$WS_FOCUSED
    sketchybar --set app_m2 label.color=$WS_UNFOCUSED
else
    sketchybar --set app_m1 label.color=$WS_UNFOCUSED
    sketchybar --set app_m2 label.color=$WS_FOCUSED
fi

# Reorder workspaces: reset to numerical order, then pin active monitors to edges
# Build single command to batch all moves (prevents visual glitching)
move_cmd=""

# Step 1: Reset all workspaces to numerical order
prev_item="app_m1"
for space_id in $WORKSPACES; do
    move_cmd+=" --move space.$space_id after $prev_item"
    prev_item="space.$space_id"
    for i in $(seq 0 $((MAX_ICONS - 1))); do
        move_cmd+=" --move space.$space_id.icon.$i after $prev_item"
        prev_item="space.$space_id.icon.$i"
    done
done

# Step 2: Pin left monitor's workspace first (after app_m1)
if [[ -n "$m1_ws" ]]; then
    move_cmd+=" --move space.$m1_ws after app_m1"
    for i in $(seq 0 $((MAX_ICONS - 1))); do
        if [[ $i -eq 0 ]]; then
            move_cmd+=" --move space.$m1_ws.icon.$i after space.$m1_ws"
        else
            move_cmd+=" --move space.$m1_ws.icon.$i after space.$m1_ws.icon.$((i-1))"
        fi
    done
fi

# Step 3: Pin right monitor's workspace last (before spaces_spacer)
if [[ -n "$m2_ws" && "$m2_ws" != "$m1_ws" ]]; then
    move_cmd+=" --move space.$m2_ws before spaces_spacer"
    for i in $(seq 0 $((MAX_ICONS - 1))); do
        if [[ $i -eq 0 ]]; then
            move_cmd+=" --move space.$m2_ws.icon.$i after space.$m2_ws"
        else
            move_cmd+=" --move space.$m2_ws.icon.$i after space.$m2_ws.icon.$((i-1))"
        fi
    done
fi

# Execute all moves in single call
sketchybar $move_cmd 2>/dev/null

# Update JankyBorders colour based on focused window layout
"$CONFIG_DIR/plugins/borders.sh" 2>/dev/null &
