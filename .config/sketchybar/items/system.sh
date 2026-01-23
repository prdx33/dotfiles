#!/bin/bash

# System stats - one unified pill
# Layout: ● 12MS D 23K U 138K | MEM 38% [graph] | CPU 32% [graph] | GPU 12% [graph] | R 32KB W 32MB

source "$CONFIG_DIR/colours.sh"

ITEM_HEIGHT=32
GRAPH_WIDTH=60

# Ping with green dot
sketchybar --add item ping right \
    --set ping \
        icon="●" \
        icon.font="$FONT:Bold:10.0" \
        icon.color=$PING_GOOD \
        icon.padding_left=10 \
        label.font="$FONT:Bold:10.0" \
        label.color=$STAT_LABEL \
        label.padding_right=6 \
        background.drawing=off \
        update_freq=5 \
        script="$PLUGIN_DIR/ping.sh"

# Network down
sketchybar --add item net_down right \
    --set net_down \
        icon="D" \
        icon.font="$FONT:Bold:10.0" \
        icon.color=$STAT_LABEL \
        label.font="$FONT:Bold:10.0" \
        label.color=$STAT_LABEL \
        label.padding_right=6 \
        background.drawing=off

# Network up
sketchybar --add item net_up right \
    --set net_up \
        icon="U" \
        icon.font="$FONT:Bold:10.0" \
        icon.color=$STAT_LABEL \
        label.font="$FONT:Bold:10.0" \
        label.color=$STAT_LABEL \
        label.padding_right=10 \
        background.drawing=off \
        update_freq=2 \
        script="$PLUGIN_DIR/network.sh"

# Memory with graph
sketchybar --add graph memory right $GRAPH_WIDTH \
    --set memory \
        icon.drawing=off \
        label.font="$FONT:Bold:10.0" \
        label.color=$STAT_LABEL \
        label.align=left \
        label.y_offset=6 \
        label.padding_left=6 \
        label.padding_right=6 \
        graph.color=$GRAPH_LINE \
        graph.fill_color=$GRAPH_FILL \
        graph.line_width=1.0 \
        background.drawing=off \
        update_freq=5 \
        script="$PLUGIN_DIR/memory.sh"

# CPU with graph
sketchybar --add graph cpu right $GRAPH_WIDTH \
    --set cpu \
        icon.drawing=off \
        label.font="$FONT:Bold:10.0" \
        label.color=$STAT_LABEL \
        label.align=left \
        label.y_offset=6 \
        label.padding_left=6 \
        label.padding_right=6 \
        graph.color=$GRAPH_LINE \
        graph.fill_color=$GRAPH_FILL \
        graph.line_width=1.0 \
        background.drawing=off \
        update_freq=2 \
        script="$PLUGIN_DIR/cpu.sh"

# GPU with graph
sketchybar --add graph gpu right $GRAPH_WIDTH \
    --set gpu \
        icon.drawing=off \
        label.font="$FONT:Bold:10.0" \
        label.color=$STAT_LABEL \
        label.align=left \
        label.y_offset=6 \
        label.padding_left=6 \
        label.padding_right=6 \
        graph.color=$GRAPH_LINE \
        graph.fill_color=$GRAPH_FILL \
        graph.line_width=1.0 \
        background.drawing=off \
        update_freq=3 \
        script="$PLUGIN_DIR/gpu.sh"

# Disk read
sketchybar --add item disk_read right \
    --set disk_read \
        icon="R" \
        icon.font="$FONT:Bold:10.0" \
        icon.color=$STAT_LABEL \
        label.font="$FONT:Bold:10.0" \
        label.color=$STAT_LABEL \
        label.padding_right=6 \
        background.drawing=off

# Disk write
sketchybar --add item disk_write right \
    --set disk_write \
        icon="W" \
        icon.font="$FONT:Bold:10.0" \
        icon.color=$STAT_LABEL \
        icon.padding_left=6 \
        label.font="$FONT:Bold:10.0" \
        label.color=$STAT_LABEL \
        label.padding_right=10 \
        background.drawing=off \
        update_freq=3 \
        script="$PLUGIN_DIR/disk.sh"

# ONE bracket around everything (no pill, just blur)
sketchybar --add bracket stats_bracket ping net_down net_up memory cpu gpu disk_read disk_write \
    --set stats_bracket \
        background.drawing=off
