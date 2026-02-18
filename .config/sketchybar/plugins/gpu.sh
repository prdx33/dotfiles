#!/bin/bash

# GPU plugin - 6-tier with very generous baseline (normal use ~50%+)
# Sharp curve: stays white most of the time, ramps fast at high end
# Thresholds: 0-70 idle, 70-80, 80-88, 88-93, 93-97, 97+

source "$CONFIG_DIR/colours.sh" 2>/dev/null || exit 0

gpu=$(ioreg -r -d 1 -c IOAccelerator 2>/dev/null | grep -o '"Device Utilization %"=[0-9]*' | grep -o '[0-9]*' | head -1)
[[ -z "$gpu" ]] && gpu=0
[[ ! "$gpu" =~ ^[0-9]+$ ]] && gpu=0
[[ $gpu -gt 99 ]] && gpu=99

if [[ $gpu -ge 97 ]]; then color=$TIER_5
elif [[ $gpu -ge 93 ]]; then color=$TIER_4
elif [[ $gpu -ge 88 ]]; then color=$TIER_3
elif [[ $gpu -ge 80 ]]; then color=$TIER_2
elif [[ $gpu -ge 70 ]]; then color=$TIER_1
else color=$TIER_0; fi

label=$(printf "%3d%%" "$gpu")

# Active stats dim to 70%, idle to 20%
if [[ -f /tmp/sketchybar_bar_faded ]]; then
    dim=$DIM_IDLE
    [[ "$color" != "$TIER_0" ]] && dim=$DIM_ACTIVE
    sketchybar --set "$NAME" label="$label" label.color=$dim \
               --set gpu_label label.color=$dim 2>/dev/null
elif [[ $gpu -ge 93 ]]; then
    sketchybar --set "$NAME" label="$label" label.color="$color" \
               --set gpu_label label.color="$color" 2>/dev/null
else
    sketchybar --set "$NAME" label="$label" label.color="$color" \
               --set gpu_label label.color="$TIER_0" 2>/dev/null
fi
