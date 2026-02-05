#!/bin/bash

# Optimised workspace change handler - only updates prev + current workspace
# Called with PREV and FOCUSED variables from aerospace

# Debounce: coalesce rapid updates, collect all touched workspaces
DEBOUNCE="/tmp/aerospace_change.ts"
TOUCHED="/tmp/aerospace_change.touched"
NOW=$(date +%s%3N)
echo "$NOW" > "$DEBOUNCE"
# Record workspaces touched during this burst
[[ -n "$PREV" ]] && echo "$PREV" >> "$TOUCHED"
[[ -n "$FOCUSED" ]] && echo "$FOCUSED" >> "$TOUCHED"
sleep 0.03
[[ "$(cat "$DEBOUNCE" 2>/dev/null)" != "$NOW" ]] && exit 0
# We won - collect touched workspaces and clean up
TOUCHED_WS=$(sort -u "$TOUCHED" 2>/dev/null | tr '\n' ' ')
rm -f "$TOUCHED"

CONFIG_DIR="$HOME/.config/sketchybar"
source "$CONFIG_DIR/colours.sh" 2>/dev/null || exit 0
source "$CONFIG_DIR/plugins/app_icons.sh" 2>/dev/null

MAX_ICONS=4
FONT_SIZE=13.0
ICON_SCALE=0.5
ICON_WIDTH=16
ICON_GAP=3
WS_ICON_GAP=5
WORKSPACE_GAP=14

# Get current workspace state (after debounce, state may have changed)
m1_ws=$(aerospace list-workspaces --monitor 1 --visible 2>/dev/null | xargs)
m2_ws=$(aerospace list-workspaces --monitor 2 --visible 2>/dev/null | xargs)
focused_ws=$(aerospace list-workspaces --focused 2>/dev/null | xargs)

# Function to update a single workspace
update_workspace() {
    local space_id="$1"
    [[ -z "$space_id" ]] && return

    # Get apps on this workspace
    local bundle_ids=$(get_workspace_apps "$space_id")
    local -a BUNDLES
    IFS=' ' read -ra BUNDLES <<< "$bundle_ids"
    local num_apps=${#BUNDLES[@]}

    # Determine state
    local icon_font icon_color icon_state
    if [[ "$space_id" == "$focused_ws" ]]; then
        icon_font="$MONO_FONT:Heavy:$FONT_SIZE"
        icon_color=$WS_FOCUSED
        icon_state="focused"
    elif [[ "$space_id" == "$m1_ws" || "$space_id" == "$m2_ws" ]]; then
        icon_font="$MONO_FONT:Regular:$FONT_SIZE"
        icon_color=$WS_FOCUSED
        icon_state="unfocused"
    else
        icon_font="$MONO_FONT:Regular:$FONT_SIZE"
        icon_color=$WS_UNFOCUSED
        icon_state="unfocused"
    fi

    # Build batch command for this workspace
    local cmd="sketchybar"

    # Workspace number visibility
    if [[ $num_apps -eq 0 && "$space_id" != "$focused_ws" && "$space_id" != "$m1_ws" && "$space_id" != "$m2_ws" ]]; then
        cmd="$cmd --set space.$space_id icon.drawing=off icon.padding_left=0 icon.padding_right=0"
    else
        cmd="$cmd --set space.$space_id icon.drawing=on icon.font=\"$icon_font\" icon.color=$icon_color icon.padding_left=$WORKSPACE_GAP icon.padding_right=$WS_ICON_GAP"
    fi

    # Update icon slots
    for i in $(seq 0 $((MAX_ICONS - 1))); do
        local item_name="space.$space_id.icon.$i"
        if [[ $i -lt $num_apps ]]; then
            local bundle="${BUNDLES[$i]}"
            local custom_icon=$(get_custom_icon_dimmed "$bundle" "$icon_state")
            if [[ -n "$custom_icon" && -f "$custom_icon" ]]; then
                cmd="$cmd --set $item_name icon.drawing=off background.image=\"$custom_icon\" background.image.scale=$ICON_SCALE background.image.drawing=on width=$(($ICON_WIDTH + $ICON_GAP))"
            else
                cmd="$cmd --set $item_name icon.drawing=off background.image=\"app.$bundle\" background.image.scale=$ICON_SCALE background.image.drawing=on width=$(($ICON_WIDTH + $ICON_GAP))"
            fi
        else
            cmd="$cmd --set $item_name icon.drawing=off background.image.drawing=off width=0"
        fi
    done

    eval "$cmd"
}

# Update only touched workspaces (debounced from burst) + currently visible
# Visible workspaces need updating for focus/unfocus styling
VISIBLE_WS="$m1_ws $m2_ws"
UPDATE_WS=$(echo "$TOUCHED_WS $VISIBLE_WS" | tr ' ' '\n' | sort -u | tr '\n' ' ' | xargs)
for ws in $UPDATE_WS; do
    update_workspace "$ws"
done
