#!/bin/bash

# Date/Time - far right

source "$CONFIG_DIR/colours.sh"

sketchybar --add item datetime right \
    --set datetime \
        icon.drawing=off \
        label.font="$FONT:Bold:11.0" \
        label.color=$LABEL_COLOR \
        label.padding_left=12 \
        label.padding_right=12 \
        background.drawing=off \
        update_freq=30 \
        script="$PLUGIN_DIR/datetime.sh" \
    --subscribe datetime system_woke
