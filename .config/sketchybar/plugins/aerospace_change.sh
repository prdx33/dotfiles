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
FONT_SIZE=10.0
ICON_SCALE=0.5
ICON_WIDTH=16
ICON_GAP=1
WS_ICON_GAP=5
WORKSPACE_GAP=14

# Get current workspace state (after debounce, state may have changed)
m1_ws=$(aerospace list-workspaces --monitor 1 --visible 2>/dev/null | xargs)
m2_ws=$(aerospace list-workspaces --monitor 2 --visible 2>/dev/null | xargs)
focused_ws=$(aerospace list-workspaces --focused 2>/dev/null | xargs)

# Single aerospace query for all window data (~22ms instead of ~22ms per workspace)
cache_all_workspace_apps

# Build single batched sketchybar command for ALL workspace updates
BATCH_CMD="sketchybar"

# Dedupe touched + visible workspaces (bash 3.2 compatible)
_seen=" "
for ws in $TOUCHED_WS $m1_ws $m2_ws; do
    [[ -z "$ws" ]] && continue
    case "$_seen" in *" $ws "*) continue ;; esac
    _seen="$_seen$ws "

    # Get apps from cache (no subprocess)
    local_bundles=$(get_cached_workspace_apps "$ws")
    IFS=' ' read -ra BUNDLES <<< "$local_bundles"
    num_apps=${#BUNDLES[@]}

    # Monitor indicators: ◂X = M1 (left), X▸ = M2 (right)
    icon_prefix=""
    icon_suffix=""
    if [[ "$ws" == "$m1_ws" ]]; then
        icon_prefix="◂"
    fi
    if [[ "$ws" == "$m2_ws" ]]; then
        icon_suffix="▸"
    fi

    # Determine state:
    # - Focused monitor: Heavy + 100%
    # - Other visible monitor: Regular + 100%
    # - Has apps but hidden: Regular + 50%
    if [[ "$ws" == "$focused_ws" ]]; then
        icon_font="$MONO_FONT:Heavy:$FONT_SIZE"
        icon_color=$WS_FOCUSED
        icon_state="focused"
    elif [[ "$ws" == "$m1_ws" || "$ws" == "$m2_ws" ]]; then
        icon_font="$MONO_FONT:Regular:$FONT_SIZE"
        icon_color=$WS_FOCUSED
        icon_state="focused"
    else
        icon_font="$MONO_FONT:Regular:$FONT_SIZE"
        icon_color=$WS_UNFOCUSED
        icon_state="unfocused"
    fi

    # Workspace visibility
    if [[ $num_apps -eq 0 && "$ws" != "$focused_ws" && "$ws" != "$m1_ws" && "$ws" != "$m2_ws" ]]; then
        BATCH_CMD="$BATCH_CMD --set space.$ws icon.drawing=off icon.padding_left=0 icon.padding_right=0"
    else
        BATCH_CMD="$BATCH_CMD --set space.$ws icon=\"${icon_prefix}${ws}${icon_suffix}\" icon.drawing=on icon.font=\"$icon_font\" icon.color=$icon_color icon.padding_left=$WORKSPACE_GAP icon.padding_right=$WS_ICON_GAP"
    fi

    # Update icon slots (literal loop, no seq subprocess)
    for i in 0 1 2 3; do
        item_name="space.$ws.icon.$i"
        if [[ $i -lt $num_apps ]]; then
            bundle="${BUNDLES[$i]}"
            custom_icon=$(get_custom_icon_dimmed "$bundle" "$icon_state")
            if [[ -n "$custom_icon" && -f "$custom_icon" ]]; then
                BATCH_CMD="$BATCH_CMD --set $item_name icon.drawing=off background.image=\"$custom_icon\" background.image.scale=$ICON_SCALE background.image.drawing=on width=$(($ICON_WIDTH + $ICON_GAP))"
            else
                BATCH_CMD="$BATCH_CMD --set $item_name icon.drawing=off background.image=\"app.$bundle\" background.image.scale=$ICON_SCALE background.image.drawing=on width=$(($ICON_WIDTH + $ICON_GAP))"
            fi
        else
            BATCH_CMD="$BATCH_CMD --set $item_name icon.drawing=off background.image.drawing=off width=0"
        fi
    done
done

# Single sketchybar IPC call for all updates
eval "$BATCH_CMD"
