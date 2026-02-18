#!/bin/bash

# Memory plugin - 6-tier with generous baseline (macOS always uses RAM)
# Thresholds: 0-55 idle, 55-70, 70-80, 80-88, 88-94, 94+

source "$CONFIG_DIR/colours.sh" 2>/dev/null || exit 0

mem_free=$(memory_pressure 2>/dev/null | grep "System-wide memory free percentage" | awk '{print $5}' | tr -d '%')
[[ -z "$mem_free" ]] && mem_free=50
[[ ! "$mem_free" =~ ^[0-9]+$ ]] && mem_free=50

mem_used=$((100 - mem_free))
[[ $mem_used -gt 99 ]] && mem_used=99

if [[ $mem_used -ge 94 ]]; then color=$TIER_5
elif [[ $mem_used -ge 88 ]]; then color=$TIER_4
elif [[ $mem_used -ge 80 ]]; then color=$TIER_3
elif [[ $mem_used -ge 70 ]]; then color=$TIER_2
elif [[ $mem_used -ge 55 ]]; then color=$TIER_1
else color=$TIER_0; fi

label=$(printf "%3d%%" "$mem_used")

# Active stats dim to 70%, idle to 20%
if [[ -f /tmp/sketchybar_bar_faded ]]; then
    dim=$DIM_IDLE
    [[ "$color" != "$TIER_0" ]] && dim=$DIM_ACTIVE
    sketchybar --set "$NAME" label="$label" label.color=$dim \
               --set mem_label label.color=$dim 2>/dev/null
elif [[ $mem_used -ge 88 ]]; then
    sketchybar --set "$NAME" label="$label" label.color="$color" \
               --set mem_label label.color="$color" 2>/dev/null
else
    sketchybar --set "$NAME" label="$label" label.color="$color" \
               --set mem_label label.color="$TIER_0" 2>/dev/null
fi
