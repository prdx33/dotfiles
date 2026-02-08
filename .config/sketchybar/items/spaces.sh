#!/bin/bash

# Workspaces centered - numbers only
# Clean arctic white theme

source "$CONFIG_DIR/colours.sh"

MAX_ICONS=4
FONT_SIZE=10.0
WORKSPACE_GAP=14
MONO_FONT="Iosevka Extended"

# All letter workspaces (QWERTY layout)
WORKSPACES="Q W E R T Y U I O P A S D F G H J K L Z X C V B N M"

for sid in $WORKSPACES; do
    # Workspace letter (hidden by default, shown after refresh)
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

    # App icon slots - tight grouping
    for i in $(seq 0 $((MAX_ICONS - 1))); do
        sketchybar --add item space.$sid.icon.$i center \
            --set space.$sid.icon.$i \
                icon.drawing=off \
                label.drawing=off \
                background.image.scale=0.38 \
                background.image.drawing=off \
                background.color=0x00000000 \
                padding_left=0 \
                padding_right=0 \
                width=0 \
                y_offset=1 \
                click_script="aerospace workspace $sid"
    done
done

# Corne split spacer (left shield / right shield)
# Pure empty space between shields
sketchybar --add item space_div center \
    --set space_div \
        icon.drawing=off \
        label.drawing=off \
        background.drawing=off \
        width=0

# M2 arrow is now a suffix on the workspace letter (e.g. "G▸")
# Kept as hidden placeholder for bracket compatibility
sketchybar --add item space_m2_arrow center \
    --set space_m2_arrow \
        drawing=off

# Right spacer to balance left padding
sketchybar --add item spaces_spacer center \
    --set spaces_spacer \
        icon.drawing=off \
        label.drawing=off \
        width=$WORKSPACE_GAP \
        background.drawing=off

# Bracket around workspaces (no pill)
sketchybar --add bracket spaces '/space\..*/' spaces_spacer \
    --set spaces \
        background.drawing=off

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
