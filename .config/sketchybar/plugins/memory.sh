#!/bin/bash

# Memory plugin - outputs XX% with colour thresholds

source "$CONFIG_DIR/colours.sh" 2>/dev/null || exit 0

mem_free=$(memory_pressure 2>/dev/null | grep "System-wide memory free percentage" | awk '{print $5}' | tr -d '%')
[[ -z "$mem_free" ]] && mem_free=50
[[ ! "$mem_free" =~ ^[0-9]+$ ]] && mem_free=50

mem_used=$((100 - mem_free))
[[ $mem_used -gt 99 ]] && mem_used=99

# Colour based on threshold (memory: 70% warn, 85% crit)
if [[ $mem_used -ge 85 ]]; then
    color=$STAT_CRIT
elif [[ $mem_used -ge 70 ]]; then
    color=$STAT_WARN
else
    color=$STAT_NORMAL
fi

label=$(printf "%3d%%" "$mem_used")
sketchybar --set "$NAME" label="$label" label.color="$color" 2>/dev/null
