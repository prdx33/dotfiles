#!/bin/bash

# Network plugin using ifstat
# Fixed width format: "D XXX.XX MB" (11 chars total)

# Get speeds in Kbps
UPDOWN=$(ifstat -i en0 -b 0.1 1 2>/dev/null | tail -1)
DOWN=$(echo "$UPDOWN" | awk '{print $1}' 2>/dev/null)
UP=$(echo "$UPDOWN" | awk '{print $2}' 2>/dev/null)

# Default to 0 if empty or non-numeric
[[ -z "$DOWN" || ! "$DOWN" =~ ^[0-9.]+$ ]] && DOWN="0"
[[ -z "$UP" || ! "$UP" =~ ^[0-9.]+$ ]] && UP="0"

# Convert Kbps to MB/s (divide by 8000)
DOWN_MB=$(echo "scale=2; $DOWN / 8000" | bc 2>/dev/null) || DOWN_MB="0.00"
UP_MB=$(echo "scale=2; $UP / 8000" | bc 2>/dev/null) || UP_MB="0.00"

[[ -z "$DOWN_MB" ]] && DOWN_MB="0.00"
[[ -z "$UP_MB" ]] && UP_MB="0.00"

DOWN_FMT=$(printf "%5.2fMB" "$DOWN_MB")
UP_FMT=$(printf "%5.2fMB" "$UP_MB")

sketchybar --set net_down label="$DOWN_FMT" \
           --set net_up label="$UP_FMT" 2>/dev/null
