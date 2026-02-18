#!/bin/bash

# System stats - RIGHT side
# Order on screen (left to right): Graph | Ping | Network | Disk | CPU | GPU | MEM | DateTime

source "$CONFIG_DIR/colours.sh"

PAD=5
HALF_GAP=1
GRAPH_WIDTH=30
STAT_WIDTH=23
IO_WIDTH=5

# === Spacer between datetime and CPU ===
sketchybar --add item spacer.date_cpu right \
    --set spacer.date_cpu \
        icon.drawing=off \
        label.drawing=off \
        width=4 \
        background.drawing=off

# === CPU (stacked: label top, value bottom) ===
sketchybar --add item cpu_label right \
    --set cpu_label \
        icon.drawing=off \
        label=" CPU" \
        label.font="Iosevka Extended:Bold:8.0" \
        label.color=$TIER_0 \
        label.width=$STAT_WIDTH \
        padding_right=$HALF_GAP \
        y_offset=6 \
        width=0 \
        background.drawing=off

sketchybar --add item cpu right \
    --set cpu \
        icon.drawing=off \
        label.font="$MONO_FONT:Light:8.0" \
        label.color=$TIER_0 \
        label.width=$STAT_WIDTH \
        padding_right=$HALF_GAP \
        y_offset=-4 \
        background.drawing=off \
        update_freq=5 \
        script="$PLUGIN_DIR/cpu.sh"

# === GPU (stacked) ===
sketchybar --add item gpu_label right \
    --set gpu_label \
        icon.drawing=off \
        label=" GPU" \
        label.font="Iosevka Extended:Bold:8.0" \
        label.color=$TIER_0 \
        label.width=$STAT_WIDTH \
        padding_right=$HALF_GAP \
        y_offset=6 \
        width=0 \
        background.drawing=off

sketchybar --add item gpu right \
    --set gpu \
        icon.drawing=off \
        label.font="$MONO_FONT:Light:8.0" \
        label.color=$TIER_0 \
        label.width=$STAT_WIDTH \
        padding_right=$HALF_GAP \
        y_offset=-4 \
        background.drawing=off \
        update_freq=5 \
        script="$PLUGIN_DIR/gpu.sh"

# === Memory (stacked) ===
sketchybar --add item mem_label right \
    --set mem_label \
        icon.drawing=off \
        label=" MEM" \
        label.font="Iosevka Extended:Bold:8.0" \
        label.color=$TIER_0 \
        label.width=$STAT_WIDTH \
        padding_right=$HALF_GAP \
        y_offset=6 \
        width=0 \
        background.drawing=off

sketchybar --add item memory right \
    --set memory \
        icon.drawing=off \
        label.font="$MONO_FONT:Light:8.0" \
        label.color=$TIER_0 \
        label.width=$STAT_WIDTH \
        padding_right=$HALF_GAP \
        y_offset=-4 \
        background.drawing=off \
        update_freq=5 \
        script="$PLUGIN_DIR/memory.sh"

# === I/O Unit — merged UD/RW with status dots ===
# Layout on screen:  [● D U]  (top: ping dot, download, upload)
#                    [● R W]  (bottom: disk dot, read, write)
# Convention: Download before Upload (network standard)
# Added right-to-left: U/W column, D/R column, dots column
DOT_WIDTH=8

# Column 3 (rightmost): U top / W bottom
sketchybar --add item net_up right \
    --set net_up \
        icon="U" \
        icon.font="Iosevka Extended:Bold:8.0" \
        icon.color=$TIER_0 \
        icon.width=$IO_WIDTH \
        label.drawing=off \
        padding_right=6 \
        y_offset=6 \
        width=0 \
        background.drawing=off

sketchybar --add item disk_write right \
    --set disk_write \
        icon="W" \
        icon.font="$MONO_FONT:Light:8.0" \
        icon.color=$TIER_0 \
        icon.width=$IO_WIDTH \
        label.drawing=off \
        padding_right=6 \
        y_offset=-4 \
        background.drawing=off \
        update_freq=5 \
        script="$PLUGIN_DIR/disk.sh"

# Column 2: D top / R bottom
sketchybar --add item net_down right \
    --set net_down \
        icon="D" \
        icon.font="Iosevka Extended:Bold:8.0" \
        icon.color=$TIER_0 \
        icon.width=$IO_WIDTH \
        label.drawing=off \
        padding_right=0 \
        y_offset=6 \
        width=0 \
        background.drawing=off \
        update_freq=5 \
        script="$PLUGIN_DIR/network.sh" \
    --subscribe net_down system_woke

sketchybar --add item disk_read right \
    --set disk_read \
        icon="R" \
        icon.font="$MONO_FONT:Light:8.0" \
        icon.color=$TIER_0 \
        icon.width=$IO_WIDTH \
        label.drawing=off \
        padding_right=0 \
        y_offset=-4 \
        background.drawing=off

# Column 1 (leftmost): ping dot top / disk dot bottom
sketchybar --add item ping right \
    --set ping \
        icon="●" \
        icon.font="$MONO_FONT:Light:6.0" \
        icon.color=$PING_GOOD \
        icon.width=$DOT_WIDTH \
        label.drawing=off \
        padding_left=$PAD \
        padding_right=0 \
        y_offset=7 \
        width=0 \
        background.drawing=off \
        update_freq=5 \
        script="$PLUGIN_DIR/ping.sh"

sketchybar --add item disk_dot right \
    --set disk_dot \
        icon="●" \
        icon.font="$MONO_FONT:Light:6.0" \
        icon.color=$TIER_0 \
        icon.width=$DOT_WIDTH \
        label.drawing=off \
        padding_left=$PAD \
        padding_right=0 \
        y_offset=-3 \
        background.drawing=off

# === API spend (stacked: label top, value bottom) ===
# Right-aligned via printf in plugin — 7 char max "$XXX.XX"
API_WIDTH=22

sketchybar --add item claude_api_label right \
    --set claude_api_label \
        icon.drawing=off \
        label=" API" \
        label.font="Iosevka Extended:Bold:8.0" \
        label.color=$LABEL_COLOR \
        label.width=$API_WIDTH \
        padding_left=$PAD \
        padding_right=$HALF_GAP \
        y_offset=6 \
        width=0 \
        background.drawing=off

sketchybar --add item claude_api right \
    --set claude_api \
        icon.drawing=off \
        label.font="$MONO_FONT:Light:8.0" \
        label.color=$STAT_LABEL \
        label.width=$API_WIDTH \
        padding_left=$PAD \
        padding_right=$HALF_GAP \
        y_offset=-4 \
        background.drawing=off \
        update_freq=300 \
        script="$PLUGIN_DIR/claude.sh" \
    --subscribe claude_api system_woke

# === Network Graph (download only) ===
sketchybar --add graph net_graph right $GRAPH_WIDTH \
    --set net_graph \
        icon.drawing=off \
        label.drawing=off \
        padding_left=$PAD \
        padding_right=$PAD \
        graph.color=0xccffffff \
        graph.fill_color=0x00000000 \
        graph.line_width=1.0 \
        background.drawing=off \
        update_freq=5 \
        script="$PLUGIN_DIR/net_graph.sh"
