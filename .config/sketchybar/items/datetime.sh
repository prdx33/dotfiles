#!/bin/bash

# Date/Time - stacked, rightmost position
# Date on top, Time on bottom

source "$CONFIG_DIR/colours.sh"

DATETIME_WIDTH=55

# Date (top) - same padding_right as time for alignment
sketchybar --add item date right \
    --set date \
        icon.drawing=off \
        label.font="Iosevka Extended:Heavy:9.0" \
        label.color=$LABEL_COLOR \
        label.width=$DATETIME_WIDTH \
        padding_right=0 \
        y_offset=7 \
        width=0 \
        background.drawing=off

# Time (bottom) - padding_right for edge spacing
sketchybar --add item time right \
    --set time \
        icon.drawing=off \
        label.font="$MONO_FONT:Regular:9.0" \
        label.color=$LABEL_COLOR \
        label.width=$DATETIME_WIDTH \
        padding_right=0 \
        y_offset=-5 \
        background.drawing=off \
        update_freq=30 \
        script="$PLUGIN_DIR/datetime.sh" \
    --subscribe time system_woke
