#!/bin/bash

# Ping plugin - outputs XXms with colored dot

source "$CONFIG_DIR/colours.sh"

ping_ms=""
for target in 192.168.1.1 10.0.0.1 8.8.8.8; do
    ping_ms=$(ping -c 1 -W 1 "$target" 2>/dev/null | grep "time=" | sed 's/.*time=\([0-9.]*\).*/\1/' | cut -d. -f1)
    [[ -n "$ping_ms" ]] && break
done

if [[ -n "$ping_ms" && "$ping_ms" =~ ^[0-9]+$ ]]; then
    if [[ $ping_ms -lt 30 ]]; then
        color=$PING_GOOD
    elif [[ $ping_ms -lt 80 ]]; then
        color=$PING_MED
    else
        color=$PING_BAD
    fi
    sketchybar --set $NAME label="${ping_ms}MS" icon.color=$color
else
    sketchybar --set $NAME label="--" icon.color=$PING_BAD
fi
