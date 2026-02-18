#!/bin/bash

# Bar fade — dims all visible items to 20% on idle
# Restores to defaults on activity; plugins fix dynamic colours on next tick

IDLE_THRESHOLD=8
STATEFILE="/tmp/sketchybar_bar_faded"
DIM=0x33ffffff
RESTORE=0xccffffff
MAX_MENUS=14

idle_ns=$(ioreg -c IOHIDSystem | awk '/HIDIdleTime/{print $NF; exit}')
[[ -z "$idle_ns" ]] && exit 0
idle_s=$((idle_ns / 1000000000))

# All letter workspaces
WS="Q W E R T Y U I O P A S D F G H J K L Z X C V B N M"

if [[ $idle_s -ge $IDLE_THRESHOLD ]]; then
    [[ -f "$STATEFILE" ]] && exit 0
    touch "$STATEFILE"

    # Build one big sketchybar command
    args=(
        --set app_name label.color=$DIM
        --set app_icon background.image.drawing=off
        --set cpu_label label.color=$DIM
        --set cpu label.color=$DIM
        --set gpu_label label.color=$DIM
        --set gpu label.color=$DIM
        --set mem_label label.color=$DIM
        --set memory label.color=$DIM
        --set net_up icon.color=$DIM
        --set net_down icon.color=$DIM
        --set disk_read icon.color=$DIM
        --set disk_write icon.color=$DIM
        --set ping icon.color=$DIM
        --set disk_dot icon.color=$DIM
        --set claude_api_label label.color=$DIM
        --set claude_api label.color=$DIM
        --set date label.color=$DIM
        --set time label.color=$DIM
        --set net_graph graph.color=0x15ffffff graph.fill_color=0x00000000
    )

    # Workspaces
    for sid in $WS; do
        args+=(--set "space.$sid" icon.color=$DIM)
    done

    # Menus
    for i in $(seq 0 $((MAX_MENUS - 1))); do
        args+=(--set "menu.$i" label.color=$DIM)
    done

    sketchybar "${args[@]}" 2>/dev/null

else
    [[ ! -f "$STATEFILE" ]] && exit 0
    rm -f "$STATEFILE"

    args=(
        --set app_name label.color=0xffffffff
        --set app_icon background.image.drawing=on
        --set cpu_label label.color=$RESTORE
        --set cpu label.color=$RESTORE
        --set gpu_label label.color=$RESTORE
        --set gpu label.color=$RESTORE
        --set mem_label label.color=$RESTORE
        --set memory label.color=$RESTORE
        --set net_up icon.color=$RESTORE
        --set net_down icon.color=$RESTORE
        --set disk_read icon.color=$RESTORE
        --set disk_write icon.color=$RESTORE
        --set ping icon.color=$RESTORE
        --set disk_dot icon.color=$RESTORE
        --set claude_api_label label.color=$RESTORE
        --set claude_api label.color=$RESTORE
        --set date label.color=$RESTORE
        --set time label.color=$RESTORE
        --set net_graph graph.color=0xccffffff graph.fill_color=0x00000000
    )

    # Workspaces — restore to unfocused default; refresh script fixes focused state
    for sid in $WS; do
        args+=(--set "space.$sid" icon.color=$RESTORE)
    done

    # Menus
    for i in $(seq 0 $((MAX_MENUS - 1))); do
        args+=(--set "menu.$i" label.color=0x33ffffff)
    done

    sketchybar "${args[@]}" 2>/dev/null
fi
