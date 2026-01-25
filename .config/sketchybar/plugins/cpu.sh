#!/bin/bash

# CPU plugin - outputs XX% with colour thresholds

source "$CONFIG_DIR/colours.sh" 2>/dev/null || exit 0

cpu_line=$(top -l 1 -n 0 2>/dev/null | grep "CPU usage")
user=$(echo "$cpu_line" | awk '{print $3}' | tr -d '%')
sys=$(echo "$cpu_line" | awk '{print $5}' | tr -d '%')

cpu=$(echo "$user + $sys" | bc 2>/dev/null | cut -d. -f1)
[[ -z "$cpu" ]] && cpu=0
[[ ! "$cpu" =~ ^[0-9]+$ ]] && cpu=0
[[ $cpu -gt 99 ]] && cpu=99

# Colour based on threshold
if [[ $cpu -ge 90 ]]; then
    color=$STAT_CRIT
elif [[ $cpu -ge 75 ]]; then
    color=$STAT_WARN
else
    color=$STAT_NORMAL
fi

label=$(printf "%2d%%" "$cpu")
sketchybar --set "$NAME" label="$label" label.color="$color" 2>/dev/null
