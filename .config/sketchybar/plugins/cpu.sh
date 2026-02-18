#!/bin/bash

# CPU plugin - 6-tier with generous baseline, sharp ramp at end
# Thresholds: 0-40 idle, 40-60, 60-75, 75-87, 87-94, 94+

source "$CONFIG_DIR/colours.sh" 2>/dev/null || exit 0

cores=$(sysctl -n hw.ncpu)
cpu=$(ps -A -o %cpu | awk -v c="$cores" '{s+=$1} END {printf "%.0f", s/c}')

[[ -z "$cpu" ]] && cpu=0
[[ ! "$cpu" =~ ^[0-9]+$ ]] && cpu=0
[[ $cpu -gt 99 ]] && cpu=99

if [[ $cpu -ge 94 ]]; then color=$TIER_5
elif [[ $cpu -ge 87 ]]; then color=$TIER_4
elif [[ $cpu -ge 75 ]]; then color=$TIER_3
elif [[ $cpu -ge 60 ]]; then color=$TIER_2
elif [[ $cpu -ge 40 ]]; then color=$TIER_1
else color=$TIER_0; fi

label=$(printf "%3d%%" "$cpu")

# Respect idle fade — active stats dim to 70%, idle to 20%
if [[ -f /tmp/sketchybar_bar_faded ]]; then
    dim=$DIM_IDLE
    [[ "$color" != "$TIER_0" ]] && dim=$DIM_ACTIVE
    sketchybar --set "$NAME" label="$label" label.color=$dim \
               --set cpu_label label.color=$dim 2>/dev/null
elif [[ $cpu -ge 87 ]]; then
    sketchybar --set "$NAME" label="$label" label.color="$color" \
               --set cpu_label label.color="$color" 2>/dev/null
else
    sketchybar --set "$NAME" label="$label" label.color="$color" \
               --set cpu_label label.color="$TIER_0" 2>/dev/null
fi
