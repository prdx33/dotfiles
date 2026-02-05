#!/bin/bash

# Refresh all workspace items (batched for performance)
# States:
# - Focused: Heavy + 100% + dot prefix
# - Other monitor visible: Regular + 50% + dot prefix
# - Has apps but hidden: Regular + 50%
# Dots: ·1 = M1 (left), 2·· = M2 (right)

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

# Letter workspaces (matching AeroSpace Alt bindings)
WORKSPACES="B C D F G I K L R S V W"

# Get visible workspace for each monitor
m1_ws=$(aerospace list-workspaces --monitor 1 --visible 2>/dev/null | xargs)
m2_ws=$(aerospace list-workspaces --monitor 2 --visible 2>/dev/null | xargs)

# Get focused workspace
focused_ws=$(aerospace list-workspaces --focused 2>/dev/null | xargs)

# Single aerospace query for all window data (~22ms instead of ~264ms)
cache_all_workspace_apps

# Build batched sketchybar command
BATCH_CMD="sketchybar"

for space_id in $WORKSPACES; do
    # Get bundle IDs from cache (no subprocess)
    bundle_ids=$(get_cached_workspace_apps "$space_id")
    IFS=' ' read -ra BUNDLES <<< "$bundle_ids"
    num_apps=${#BUNDLES[@]}

    # Determine icon prefix/suffix (dots for monitor-visible workspaces)
    # ·1 = M1 (left), 2·· = M2 (right)
    icon_prefix=""
    icon_suffix=""
    if [[ "$space_id" == "$m1_ws" ]]; then
        icon_prefix="·"
    elif [[ "$space_id" == "$m2_ws" ]]; then
        icon_suffix="··"
    fi

    # Determine state: focused = Heavy + bright, everything else = Regular + dim
    if [[ "$space_id" == "$focused_ws" ]]; then
        icon_font="$MONO_FONT:Heavy:$FONT_SIZE"
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

# Execute batched command
eval "$BATCH_CMD"

# Ensure order: letters alphabetical (B-W)
sketchybar --reorder space.B space.B.icon.0 space.B.icon.1 space.B.icon.2 space.B.icon.3 \
                     space.C space.C.icon.0 space.C.icon.1 space.C.icon.2 space.C.icon.3 \
                     space.D space.D.icon.0 space.D.icon.1 space.D.icon.2 space.D.icon.3 \
                     space.F space.F.icon.0 space.F.icon.1 space.F.icon.2 space.F.icon.3 \
                     space.G space.G.icon.0 space.G.icon.1 space.G.icon.2 space.G.icon.3 \
                     space.I space.I.icon.0 space.I.icon.1 space.I.icon.2 space.I.icon.3 \
                     space.K space.K.icon.0 space.K.icon.1 space.K.icon.2 space.K.icon.3 \
                     space.L space.L.icon.0 space.L.icon.1 space.L.icon.2 space.L.icon.3 \
                     space.R space.R.icon.0 space.R.icon.1 space.R.icon.2 space.R.icon.3 \
                     space.S space.S.icon.0 space.S.icon.1 space.S.icon.2 space.S.icon.3 \
                     space.V space.V.icon.0 space.V.icon.1 space.V.icon.2 space.V.icon.3 \
                     space.W space.W.icon.0 space.W.icon.1 space.W.icon.2 space.W.icon.3
