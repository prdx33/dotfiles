#!/bin/bash

# Refresh all workspace items (batched for performance)
# States:
# - Focused monitor: Heavy + 100%
# - Other visible monitor: Regular + 100%
# - Has apps but hidden: Regular + 50%
# Arrows: X⟵ = M1 (left), X⟶ = M2 (right)
# Layout: left shield (QWERTASDFGZXCVB) │ right shield (YUIOPHJKLNM)

# Exclusive lock — only one instance runs at a time (prevents zombie accumulation)
LOCKDIR="/tmp/aerospace_refresh.lock"
if ! mkdir "$LOCKDIR" 2>/dev/null; then
    # Lock exists — check if holder is still alive
    OLD_PID=$(cat "$LOCKDIR/pid" 2>/dev/null)
    if [[ -n "$OLD_PID" ]] && kill -0 "$OLD_PID" 2>/dev/null; then
        exit 0  # Another instance is running — skip this event
    fi
    # Stale lock from crashed process — reclaim it
    rm -rf "$LOCKDIR"
    mkdir "$LOCKDIR" 2>/dev/null || exit 0
fi
echo $$ > "$LOCKDIR/pid"
trap 'rm -rf "$LOCKDIR"' EXIT

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

# All letter workspaces
WORKSPACES="Q W E R T Y U I O P A S D F G H J K L Z X C V B N M"

# Corne shield groups
LEFT_SHIELD=" Q W E R T A S D F G Z X C V B "
RIGHT_SHIELD=" Y U I O P H J K L N M "

# Get visible workspace for each monitor
m1_ws=$(aerospace list-workspaces --monitor 1 --visible 2>/dev/null | xargs)
m2_ws=$(aerospace list-workspaces --monitor 2 --visible 2>/dev/null | xargs)

# Get focused workspace
focused_ws=$(aerospace list-workspaces --focused 2>/dev/null | xargs)

# Single aerospace query for all window data (~22ms instead of ~264ms)
cache_all_workspace_apps

# Build batched sketchybar command
BATCH_CMD="sketchybar"
has_left=0
has_right=0

for space_id in $WORKSPACES; do
    # Get bundle IDs from cache (no subprocess)
    bundle_ids=$(get_cached_workspace_apps "$space_id")
    IFS=' ' read -ra BUNDLES <<< "$bundle_ids"
    num_apps=${#BUNDLES[@]}

    # Monitor indicators: ◂X = M1 (left), X▸ = M2 (right)
    icon_prefix=""
    icon_suffix=""
    if [[ "$space_id" == "$m1_ws" ]]; then
        icon_prefix="◂"
    fi
    if [[ "$space_id" == "$m2_ws" ]]; then
        icon_suffix="▸"
    fi

    # Determine state:
    # - Focused monitor: Heavy + 100%
    # - Other visible monitor: Regular + 100%
    # - Has apps but hidden: Regular + 50%
    if [[ "$space_id" == "$focused_ws" ]]; then
        icon_font="$MONO_FONT:Heavy:$FONT_SIZE"
        icon_color=$WS_FOCUSED
        icon_state="focused"
    elif [[ "$space_id" == "$m1_ws" || "$space_id" == "$m2_ws" ]]; then
        icon_font="$MONO_FONT:Regular:$FONT_SIZE"
        icon_color=$WS_FOCUSED
        icon_state="focused"
    else
        icon_font="$MONO_FONT:Regular:$FONT_SIZE"
        icon_color=$WS_UNFOCUSED
        icon_state="unfocused"
    fi

    # Update workspace - hide if empty and not visible on any monitor
    if [[ $num_apps -eq 0 && "$space_id" != "$focused_ws" && "$space_id" != "$m1_ws" && "$space_id" != "$m2_ws" ]]; then
        BATCH_CMD="$BATCH_CMD --set space.$space_id icon.drawing=off icon.padding_left=0 icon.padding_right=0"
    else
        BATCH_CMD="$BATCH_CMD --set space.$space_id icon=\"${icon_prefix}${space_id}${icon_suffix}\" icon.drawing=on icon.font=\"$icon_font\" icon.color=$icon_color icon.padding_left=$WORKSPACE_GAP icon.padding_right=$WS_ICON_GAP"
        # Track which shield has visible workspaces
        case "$LEFT_SHIELD" in *" $space_id "*) has_left=1 ;; esac
        case "$RIGHT_SHIELD" in *" $space_id "*) has_right=1 ;; esac
    fi

    # Update icon slots
    for i in 0 1 2 3; do
        item_name="space.$space_id.icon.$i"

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

# Spacer between shields — no visual, just item ordering anchor
BATCH_CMD="$BATCH_CMD --set space_div width=0"

# Execute batched command
eval "$BATCH_CMD"

# Ensure order: Corne layout — left shield [spacer] right shield
REORDER=""
for ws in Q W E R T A S D F G Z X C V B; do
    REORDER="$REORDER space.$ws space.$ws.icon.0 space.$ws.icon.1 space.$ws.icon.2 space.$ws.icon.3"
done
REORDER="$REORDER space_div"
for ws in Y U I O P H J K L N M; do
    REORDER="$REORDER space.$ws space.$ws.icon.0 space.$ws.icon.1 space.$ws.icon.2 space.$ws.icon.3"
done
sketchybar --reorder $REORDER
