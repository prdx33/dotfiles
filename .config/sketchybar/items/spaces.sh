#!/bin/bash

# Workspaces centered - numbers only
# Clean arctic white theme

source "$CONFIG_DIR/colours.sh"

MAX_ICONS=4
FONT_SIZE=13.0
WORKSPACE_GAP=14
MONO_FONT="Iosevka Extended"

# Workspaces 1-9, 0, then 10
WORKSPACES="1 2 3 4 5 6 7 8 9 0 10"

for sid in $WORKSPACES; do
    # Workspace number only
    sketchybar --add item space.$sid center \
        --set space.$sid \
            icon="$sid" \
            icon.font="$MONO_FONT:Heavy:$FONT_SIZE" \
            icon.color=$WS_EMPTY \
            icon.padding_left=$WORKSPACE_GAP \
            icon.padding_right=4 \
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

# Controller item - handles polling and event-driven refresh
sketchybar --add item spaces_controller center \
    --set spaces_controller \
        drawing=off \
        script="$PLUGIN_DIR/aerospace_refresh.sh" \
    --subscribe spaces_controller aerospace_workspace_change system_woke

# Initial update
"$PLUGIN_DIR/aerospace_refresh.sh" &
