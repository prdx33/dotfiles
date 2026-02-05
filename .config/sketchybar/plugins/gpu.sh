#!/bin/bash

# GPU plugin - outputs XX% with colour thresholds

source "$CONFIG_DIR/colours.sh" 2>/dev/null || exit 0

gpu=$(ioreg -r -d 1 -c IOAccelerator 2>/dev/null | grep -o '"Device Utilization %"=[0-9]*' | grep -o '[0-9]*' | head -1)
[[ -z "$gpu" ]] && gpu=0
[[ ! "$gpu" =~ ^[0-9]+$ ]] && gpu=0
[[ $gpu -gt 99 ]] && gpu=99

# Colour based on threshold (gpu: 70% warn, 90% crit)
if [[ $gpu -ge 90 ]]; then
    color=$STAT_CRIT
elif [[ $gpu -ge 70 ]]; then
    color=$STAT_WARN
else
    color=$STAT_NORMAL
fi

label=$(printf "%3d%%" "$gpu")
sketchybar --set "$NAME" label="$label" label.color="$color" 2>/dev/null
