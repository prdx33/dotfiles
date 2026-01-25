#!/bin/bash

# Ping plugin - outputs "XXMS" with colour

source "$CONFIG_DIR/colours.sh" 2>/dev/null || exit 0

ping_ms=""

# Check if Mullvad is connected
mullvad_stat=$(mullvad status 2>/dev/null | head -1)

if [[ "$mullvad_stat" == "Connected" ]]; then
    ping_result=$(ping -c 1 -W 2 10.64.0.1 2>/dev/null)
    ping_ms=$(echo "$ping_result" | grep "round-trip" | awk -F'/' '{print $5}' | cut -d. -f1 2>/dev/null)
fi

# Fallback
if [[ -z "$ping_ms" ]]; then
    for target in 192.168.1.1 10.0.0.1 1.1.1.1; do
        ping_result=$(ping -c 1 -W 2 "$target" 2>/dev/null)
        ping_ms=$(echo "$ping_result" | grep "round-trip" | awk -F'/' '{print $5}' | cut -d. -f1 2>/dev/null)
        [[ -n "$ping_ms" ]] && break
    done
fi

if [[ -n "$ping_ms" && "$ping_ms" =~ ^[0-9]+$ ]]; then
    if [[ $ping_ms -lt 30 ]]; then
        color=$PING_GOOD
    elif [[ $ping_ms -lt 80 ]]; then
        color=$PING_MED
    else
        color=$PING_BAD
    fi
    sketchybar --set "$NAME" label="${ping_ms}MS" icon.color="$color" 2>/dev/null
else
    sketchybar --set "$NAME" label="--" icon.color="$PING_BAD" 2>/dev/null
fi
