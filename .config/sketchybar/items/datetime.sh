#!/bin/bash

# Date/Time - stacked, rightmost position
# Date on top, Time on bottom

source "$CONFIG_DIR/colours.sh"

# Date (top) - right aligned in fixed width
sketchybar --add item date right \
    --set date \
        icon.drawing=off \
        label.font="JetBrains Mono:Bold:9.0" \
        label.color=$LABEL_COLOR \
        label.width=60 \
        label.align=right \
        label.padding_right=8 \
        y_offset=6 \
        width=0 \
        background.drawing=off

# Time (bottom) - right aligned in fixed width
sketchybar --add item time right \
    --set time \
        icon.drawing=off \
        label.font="JetBrains Mono:Bold:9.0" \
        label.color=$LABEL_COLOR \
        label.width=60 \
        label.align=right \
        label.padding_right=8 \
        y_offset=-6 \
        background.drawing=off \
        update_freq=30 \
        script="$PLUGIN_DIR/datetime.sh" \
    --subscribe time system_woke
