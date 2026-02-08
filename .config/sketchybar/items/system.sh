#!/bin/bash

# System stats - RIGHT side
# Order on screen (left to right): Graph | Ping | Network | Disk | CPU | GPU | MEM | DateTime

source "$CONFIG_DIR/colours.sh"

PAD=5
HALF_GAP=1
GRAPH_WIDTH=30
STAT_WIDTH=26

# === Spacer between datetime and CPU ===
sketchybar --add item spacer.date_cpu right \
    --set spacer.date_cpu \
        icon.drawing=off \
        label.drawing=off \
        width=4 \
        background.drawing=off

# === CPU (stacked: label top, value bottom) ===
# Both items need same padding_right for bounding rects to align
sketchybar --add item cpu_label right \
    --set cpu_label \
        icon.drawing=off \
        label=" CPU" \
        label.font="Iosevka Extended:Bold:9.0" \
        label.color=$STAT_CPU \
        label.width=$STAT_WIDTH \
        padding_right=$HALF_GAP \
        y_offset=7 \
        width=0 \
        background.drawing=off

sketchybar --add item cpu right \
    --set cpu \
        icon.drawing=off \
        label.font="$MONO_FONT:Light:9.0" \
        label.color=$STAT_LABEL \
        label.width=$STAT_WIDTH \
        padding_right=$HALF_GAP \
        y_offset=-5 \
        background.drawing=off \
        update_freq=5 \
        script="$PLUGIN_DIR/cpu.sh"

# === GPU (stacked) ===
sketchybar --add item gpu_label right \
    --set gpu_label \
        icon.drawing=off \
        label=" GPU" \
        label.font="Iosevka Extended:Bold:9.0" \
        label.color=$STAT_GPU \
        label.width=$STAT_WIDTH \
        padding_right=$HALF_GAP \
        y_offset=7 \
        width=0 \
        background.drawing=off

sketchybar --add item gpu right \
    --set gpu \
        icon.drawing=off \
        label.font="$MONO_FONT:Light:9.0" \
        label.color=$STAT_LABEL \
        label.width=$STAT_WIDTH \
        padding_right=$HALF_GAP \
        y_offset=-5 \
        background.drawing=off \
        update_freq=5 \
        script="$PLUGIN_DIR/gpu.sh"

# === Memory (stacked) ===
sketchybar --add item mem_label right \
    --set mem_label \
        icon.drawing=off \
        label=" MEM" \
        label.font="Iosevka Extended:Bold:9.0" \
        label.color=$STAT_MEM \
        label.width=$STAT_WIDTH \
        padding_right=$HALF_GAP \
        y_offset=7 \
        width=0 \
        background.drawing=off

sketchybar --add item memory right \
    --set memory \
        icon.drawing=off \
        label.font="$MONO_FONT:Light:9.0" \
        label.color=$STAT_LABEL \
        label.width=$STAT_WIDTH \
        padding_right=$HALF_GAP \
        y_offset=-5 \
        background.drawing=off \
        update_freq=5 \
        script="$PLUGIN_DIR/memory.sh"

# === Disk (stacked: read top, write bottom) ===
# Format: "R" (Heavy) + "xxx.xxMB" (Regular)
DISK_LABEL_W=46

sketchybar --add item disk_read right \
    --set disk_read \
        icon="R" \
        icon.font="Iosevka Extended:Bold:9.0" \
        icon.color=$STAT_DISK_READ \
        icon.width=8 \
        icon.padding_right=0 \
        label="0.00MB" \
        label.font="$MONO_FONT:Light:9.0" \
        label.color=$STAT_LABEL \
        label.padding_left=0 \
        label.width=$DISK_LABEL_W \
        padding_right=$HALF_GAP \
        y_offset=7 \
        width=0 \
        background.drawing=off

sketchybar --add item disk_write right \
    --set disk_write \
        icon="W" \
        icon.font="Iosevka Extended:Bold:9.0" \
        icon.color=$STAT_DISK_WRITE \
        icon.width=8 \
        icon.padding_right=0 \
        label="0.00MB" \
        label.font="$MONO_FONT:Light:9.0" \
        label.color=$STAT_LABEL \
        label.padding_left=0 \
        label.width=$DISK_LABEL_W \
        padding_right=$HALF_GAP \
        y_offset=-5 \
        background.drawing=off \
        update_freq=5 \
        script="$PLUGIN_DIR/disk.sh"

# === Network speeds (stacked) ===
# Format: "U" (Heavy) + "xxx.xxMB" (Regular)
# padding_right here = gap toward disk (halved)
# padding_left=10 = original gap toward ping (preserved)
sketchybar --add item net_up right \
    --set net_up \
        icon="U" \
        icon.font="Iosevka Extended:Bold:9.0" \
        icon.color=$STAT_NET_UP \
        icon.width=8 \
        icon.padding_right=0 \
        label="0.00MB" \
        label.font="$MONO_FONT:Light:9.0" \
        label.color=$STAT_LABEL \
        label.padding_left=0 \
        label.width=$DISK_LABEL_W \
        padding_left=10 \
        padding_right=$HALF_GAP \
        y_offset=7 \
        width=0 \
        background.drawing=off

sketchybar --add item net_down right \
    --set net_down \
        icon="D" \
        icon.font="Iosevka Extended:Bold:9.0" \
        icon.color=$STAT_NET_DOWN \
        icon.width=8 \
        icon.padding_right=0 \
        label="0.00MB" \
        label.font="$MONO_FONT:Light:9.0" \
        label.color=$STAT_LABEL \
        label.padding_left=0 \
        label.width=$DISK_LABEL_W \
        padding_left=10 \
        padding_right=$HALF_GAP \
        y_offset=-5 \
        background.drawing=off \
        update_freq=5 \
        script="$PLUGIN_DIR/network.sh" \
    --subscribe net_down system_woke

# === Ping (dot + value together) ===
# Original spacing preserved (PAD=5)
sketchybar --add item ping right \
    --set ping \
        icon="●" \
        icon.font="$MONO_FONT:Light:8.0" \
        icon.color=$PING_GOOD \
        icon.padding_left=$PAD \
        label.font="$MONO_FONT:Light:10.0" \
        label.color=$STAT_LABEL \
        label.padding_left=3 \
        padding_right=$PAD \
        background.drawing=off \
        update_freq=5 \
        script="$PLUGIN_DIR/ping.sh"

# === Network Graph (download only) ===
# Original spacing preserved (PAD=5)
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
