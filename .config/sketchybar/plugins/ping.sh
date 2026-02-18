#!/bin/bash

# Ping plugin - colour-only dot, white at good, tiered up, red if offline
# Thresholds: 0-20 white, 20-50, 50-100, 100-150, 150-200, 200+/offline red

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
    if [[ $ping_ms -ge 200 ]]; then color=$TIER_5
    elif [[ $ping_ms -ge 150 ]]; then color=$TIER_4
    elif [[ $ping_ms -ge 100 ]]; then color=$TIER_3
    elif [[ $ping_ms -ge 50 ]]; then color=$TIER_2
    elif [[ $ping_ms -ge 20 ]]; then color=$TIER_1
    else color=$TIER_0; fi
else
    # Offline — red
    color=$TIER_5
fi

# Respect idle fade — active (non-idle ping) dims to 70%, idle to 20%
if [[ -f /tmp/sketchybar_bar_faded ]]; then
    dim=$DIM_IDLE
    [[ "$color" != "$TIER_0" ]] && dim=$DIM_ACTIVE
    sketchybar --set "$NAME" icon.color=$dim 2>/dev/null
else
    sketchybar --set "$NAME" icon.color="$color" 2>/dev/null
fi
