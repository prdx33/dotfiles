#!/bin/bash

# System stats - RIGHT side
# Order on screen (left to right): Graph | Ping | Network | Disk | CPU | GPU | MEM | DateTime

source "$CONFIG_DIR/colours.sh"

PAD=8
GRAPH_WIDTH=30

# === CPU (stacked: label top, value bottom) ===
sketchybar --add item cpu_label right \
    --set cpu_label \
        icon.drawing=off \
        label="CPU" \
        label.font="$MONO_FONT:Bold:9.0" \
        label.color=$STAT_LABEL \
        label.padding_left=$PAD \
        y_offset=6 \
        width=0 \
        background.drawing=off

sketchybar --add item cpu right \
    --set cpu \
        icon.drawing=off \
        label.font="$MONO_FONT:Bold:9.0" \
        label.color=$STAT_LABEL \
        label.padding_left=$PAD \
        y_offset=-6 \
        background.drawing=off \
        update_freq=2 \
        script="$PLUGIN_DIR/cpu.sh"

# === GPU (stacked) ===
sketchybar --add item gpu_label right \
    --set gpu_label \
        icon.drawing=off \
        label="GPU" \
        label.font="$MONO_FONT:Bold:9.0" \
        label.color=$STAT_LABEL \
        label.padding_left=$PAD \
        y_offset=6 \
        width=0 \
        background.drawing=off

sketchybar --add item gpu right \
    --set gpu \
        icon.drawing=off \
        label.font="$MONO_FONT:Bold:9.0" \
        label.color=$STAT_LABEL \
        label.padding_left=$PAD \
        y_offset=-6 \
        background.drawing=off \
        update_freq=3 \
        script="$PLUGIN_DIR/gpu.sh"

# === Memory (stacked) ===
sketchybar --add item mem_label right \
    --set mem_label \
        icon.drawing=off \
        label="MEM" \
        label.font="$MONO_FONT:Bold:9.0" \
        label.color=$STAT_LABEL \
        label.padding_left=$PAD \
        y_offset=6 \
        width=0 \
        background.drawing=off

sketchybar --add item memory right \
    --set memory \
        icon.drawing=off \
        label.font="$MONO_FONT:Bold:9.0" \
        label.color=$STAT_LABEL \
        label.padding_left=$PAD \
        y_offset=-6 \
        background.drawing=off \
        update_freq=5 \
        script="$PLUGIN_DIR/memory.sh"

# === Disk (stacked: read top, write bottom) ===
sketchybar --add item disk_read right \
    --set disk_read \
        icon.drawing=off \
        label.font="$MONO_FONT:Bold:9.0" \
        label.color=$STAT_LABEL \
        label.padding_left=$PAD \
        y_offset=6 \
        width=0 \
        background.drawing=off

sketchybar --add item disk_write right \
    --set disk_write \
        icon.drawing=off \
        label.font="$MONO_FONT:Bold:9.0" \
        label.color=$STAT_LABEL \
        label.padding_left=$PAD \
        y_offset=-6 \
        background.drawing=off \
        update_freq=3 \
        script="$PLUGIN_DIR/disk.sh"

# === Network speeds (stacked) ===
sketchybar --add item net_down right \
    --set net_down \
        icon.drawing=off \
        label.font="$MONO_FONT:Bold:9.0" \
        label.color=$STAT_LABEL \
        label.padding_left=$PAD \
        y_offset=6 \
        width=0 \
        background.drawing=off

sketchybar --add item net_up right \
    --set net_up \
        icon.drawing=off \
        label.font="$MONO_FONT:Bold:9.0" \
        label.color=$STAT_LABEL \
        label.padding_left=$PAD \
        y_offset=-6 \
        background.drawing=off \
        update_freq=2 \
        script="$PLUGIN_DIR/network.sh" \
    --subscribe net_up system_woke

# === Ping (dot + value together) ===
sketchybar --add item ping right \
    --set ping \
        icon="●" \
        icon.font="$MONO_FONT:Bold:8.0" \
        icon.color=$PING_GOOD \
        icon.padding_left=$PAD \
        label.font="$MONO_FONT:Bold:10.0" \
        label.color=$STAT_LABEL \
        label.padding_left=3 \
        background.drawing=off \
        update_freq=5 \
        script="$PLUGIN_DIR/ping.sh"

# === Network Graph (download only) ===
sketchybar --add graph net_graph right $GRAPH_WIDTH \
    --set net_graph \
        icon.drawing=off \
        label.drawing=off \
        padding_left=$PAD \
        graph.color=0xccffffff \
        graph.fill_color=0x00000000 \
        graph.line_width=1.0 \
        background.drawing=off \
        update_freq=2 \
        script="$PLUGIN_DIR/net_graph.sh"
