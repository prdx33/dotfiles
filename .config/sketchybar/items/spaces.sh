#!/bin/bash

# Workspaces - split layout with centre divider
# All items center-positioned. Balance spacer compensates for asymmetric content.
# Left group (mirrored): [icons][letter], M1 innermost at divider
# Right group (normal):  [letter][icons], M2 innermost at divider

source "$CONFIG_DIR/colours.sh"

MAX_ICONS=4
FONT_SIZE=10.0
WORKSPACE_GAP=11
MONO_FONT="Iosevka Extended"

WORKSPACES="Q W E R T Y U I O P A S D F G H J K L Z X C V B N M"

for sid in $WORKSPACES; do
    sketchybar --add item space.$sid center \
        --set space.$sid \
            icon="$sid" \
            icon.font="$MONO_FONT:Heavy:$FONT_SIZE" \
            icon.color=$WS_EMPTY \
            icon.drawing=off \
            icon.padding_left=0 \
            icon.padding_right=0 \
            label.drawing=off \
            background.drawing=off \
            click_script="aerospace workspace $sid"

    # Gap right — before letter (leading spacer)
    sketchybar --add item space.$sid.gr center \
        --set space.$sid.gr \
            icon.drawing=off \
            label.drawing=off \
            background.drawing=off \
            width=0

    for i in $(seq 0 $((MAX_ICONS - 1))); do
        sketchybar --add item space.$sid.icon.$i center \
            --set space.$sid.icon.$i \
                icon.drawing=off \
                label.drawing=off \
                background.image.scale=0.5 \
                background.image.drawing=off \
                background.color=0x00000000 \
                padding_left=0 \
                padding_right=0 \
                width=0 \
                y_offset=1 \
                click_script="aerospace workspace $sid"
    done

    # Gap left — after last icon (trailing spacer)
    sketchybar --add item space.$sid.gl center \
        --set space.$sid.gl \
            icon.drawing=off \
            label.drawing=off \
            background.drawing=off \
            width=0
done

# Arrow indicators for active workspaces (M1=◂, M2=▸) — 6px each
sketchybar --add item space_arrow_m1 center \
    --set space_arrow_m1 \
        icon="«" \
        icon.font="$MONO_FONT:Regular:$FONT_SIZE" \
        icon.color=$WS_FOCUSED \
        icon.drawing=off \
        icon.padding_left=0 \
        icon.padding_right=0 \
        label.drawing=off \
        background.drawing=off \
        width=0

sketchybar --add item space_arrow_m2 center \
    --set space_arrow_m2 \
        icon="»" \
        icon.font="$MONO_FONT:Regular:$FONT_SIZE" \
        icon.color=$WS_FOCUSED \
        icon.drawing=off \
        icon.padding_left=0 \
        icon.padding_right=0 \
        label.drawing=off \
        background.drawing=off \
        width=0

# Centre divider — invisible spacer between left and right groups
sketchybar --add item space_div center \
    --set space_div \
        icon.drawing=off \
        label.drawing=off \
        background.drawing=off \
        width=10

# Balance spacer — sits at end of right group, width set dynamically
sketchybar --add item space_balance center \
    --set space_balance \
        icon.drawing=off \
        label.drawing=off \
        background.drawing=off \
        width=0

# Workspace change events
sketchybar --add event aerospace_workspace_change

# Controller for workspace switches (fast partial update via PREV/FOCUSED vars)
sketchybar --add item spaces_controller center \
    --set spaces_controller \
        drawing=off \
        script="$PLUGIN_DIR/aerospace_change.sh" \
    --subscribe spaces_controller aerospace_workspace_change

# Controller for full refresh on wake, app changes, and space changes
sketchybar --add item spaces_refresh center \
    --set spaces_refresh \
        drawing=off \
        script="$PLUGIN_DIR/aerospace_refresh.sh" \
    --subscribe spaces_refresh system_woke front_app_switched space_change

# Initial update - retry until aerospace is ready
(for i in 1 2 3 5; do
    sleep "$i"
    aerospace list-workspaces --focused 2>/dev/null | grep -q . && {
        "$PLUGIN_DIR/aerospace_refresh.sh"
        break
    }
done) &
