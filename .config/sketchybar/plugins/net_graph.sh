#!/bin/bash

# Network graph plugin - dynamic opacity based on throughput
# Very faint at idle, progressively brighter across tiers

MAX_KBPS=10000  # 10 Mbps max for normalization

# Use default route interface
IFACE=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')
[[ -z "$IFACE" ]] && IFACE="en0"

# Get download speed in Kbps
UPDOWN=$(ifstat -i "$IFACE" -b 0.1 1 2>/dev/null | tail -1)
DOWN=$(echo "$UPDOWN" | awk '{print $1}' 2>/dev/null | cut -f1 -d.)

[[ -z "$DOWN" || ! "$DOWN" =~ ^[0-9]+$ ]] && DOWN=0

# Normalize to 0-1
DOWN_VAL=$(echo "scale=4; $DOWN / $MAX_KBPS" | bc 2>/dev/null) || DOWN_VAL=0
[[ -z "$DOWN_VAL" ]] && DOWN_VAL=0
[[ $(echo "$DOWN_VAL > 1" | bc 2>/dev/null) -eq 1 ]] && DOWN_VAL=1
[[ $(echo "$DOWN_VAL < 0.02" | bc 2>/dev/null) -eq 1 ]] && [[ $DOWN -gt 0 ]] && DOWN_VAL=0.02

# Dynamic opacity — faint at idle, bright at high throughput
if [[ $DOWN -ge 8000 ]]; then
    line=0xddffffff; fill=0x50ffffff
elif [[ $DOWN -ge 3000 ]]; then
    line=0x99ffffff; fill=0x35ffffff
elif [[ $DOWN -ge 1000 ]]; then
    line=0x66ffffff; fill=0x22ffffff
elif [[ $DOWN -ge 200 ]]; then
    line=0x40ffffff; fill=0x15ffffff
elif [[ $DOWN -ge 10 ]]; then
    line=0x25ffffff; fill=0x0affffff
else
    line=0x12ffffff; fill=0x05ffffff
fi

sketchybar --set net_graph graph.color="$line" graph.fill_color="$fill" \
           --push net_graph $DOWN_VAL 2>/dev/null
