#!/bin/bash

# Network graph plugin - download only

MAX_KBPS=10000  # 10 Mbps max

# Get download speed in Kbps
UPDOWN=$(ifstat -i en0 -b 0.1 1 2>/dev/null | tail -1)
DOWN=$(echo "$UPDOWN" | awk '{print $1}' 2>/dev/null | cut -f1 -d.)

[[ -z "$DOWN" || ! "$DOWN" =~ ^[0-9]+$ ]] && DOWN=0

# Normalize to 0-1
DOWN_VAL=$(echo "scale=4; $DOWN / $MAX_KBPS" | bc 2>/dev/null) || DOWN_VAL=0

[[ -z "$DOWN_VAL" ]] && DOWN_VAL=0
[[ $(echo "$DOWN_VAL > 1" | bc 2>/dev/null) -eq 1 ]] && DOWN_VAL=1

# Minimum visibility
[[ $(echo "$DOWN_VAL < 0.02" | bc 2>/dev/null) -eq 1 ]] && [[ $DOWN -gt 0 ]] && DOWN_VAL=0.02

sketchybar --push net_graph $DOWN_VAL 2>/dev/null
