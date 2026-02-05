#!/bin/bash

# CPU plugin - outputs XX% with colour thresholds
# Uses ps instead of top for ~24x faster execution

source "$CONFIG_DIR/colours.sh" 2>/dev/null || exit 0

# Sum all process CPU and normalise by core count
cores=$(sysctl -n hw.ncpu)
cpu=$(ps -A -o %cpu | awk -v c="$cores" '{s+=$1} END {printf "%.0f", s/c}')

[[ -z "$cpu" ]] && cpu=0
[[ ! "$cpu" =~ ^[0-9]+$ ]] && cpu=0
[[ $cpu -gt 99 ]] && cpu=99

# Colour based on threshold (cpu: 70% warn, 85% crit)
if [[ $cpu -ge 85 ]]; then
    color=$STAT_CRIT
elif [[ $cpu -ge 70 ]]; then
    color=$STAT_WARN
else
    color=$STAT_NORMAL
fi

label=$(printf "%3d%%" "$cpu")
sketchybar --set "$NAME" label="$label" label.color="$color" 2>/dev/null
