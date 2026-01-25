#!/bin/bash

# Workspaces centered, with active app names flanking
# Clean arctic white theme, no dots

source "$CONFIG_DIR/colours.sh"

MAX_ICONS=4
FONT_SIZE=17.0
WORKSPACE_GAP=14
MONO_FONT="Iosevka Extended"

# Left app (monitor 1) - fixed width for centering balance
sketchybar --add item app_m1 center \
    --set app_m1 \
        icon.drawing=off \
        label.font="$MONO_FONT:Bold:11.0" \
        label.color=$WS_FOCUSED \
        label.width=100 \
        label.align=right \
        label.padding_right=15 \
        background.drawing=off \
        update_freq=2 \
        script="$PLUGIN_DIR/front_app.sh 1" \
    --subscribe app_m1 front_app_switched aerospace_workspace_change system_woke

# Workspaces 1-9, 0, then 10
WORKSPACES="1 2 3 4 5 6 7 8 9 0 10"

for sid in $WORKSPACES; do
    # Workspace number only
    sketchybar --add item space.$sid center \
        --set space.$sid \
            icon="$sid" \
            icon.font="$MONO_FONT:Bold:$FONT_SIZE" \
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

# Right app (monitor 2) - fixed width for centering balance
sketchybar --add item app_m2 center \
    --set app_m2 \
        icon.drawing=off \
        label.font="$MONO_FONT:Bold:11.0" \
        label.color=$WS_FOCUSED \
        label.width=100 \
        label.align=left \
        label.padding_left=10 \
        background.drawing=off \
        update_freq=2 \
        script="$PLUGIN_DIR/front_app.sh 2" \
    --subscribe app_m2 front_app_switched aerospace_workspace_change

# Workspace change events
sketchybar --add event aerospace_workspace_change
for sid in $WORKSPACES; do
    sketchybar --subscribe space.$sid aerospace_workspace_change
    for i in $(seq 0 $((MAX_ICONS - 1))); do
        sketchybar --subscribe space.$sid.icon.$i aerospace_workspace_change
    done
done

# Initial update
for sid in $WORKSPACES; do
    "$PLUGIN_DIR/aerospace.sh" "$sid" &
done
