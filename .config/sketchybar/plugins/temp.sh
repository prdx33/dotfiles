#!/bin/bash

# Temperature plugin - shows "󰔏XX°"

TEMP_RAW=$(ioreg -r -n AppleSmartBattery 2>/dev/null | grep '"Temperature"' | head -1 | grep -oE '[0-9]+')

if [[ -n "$TEMP_RAW" ]]; then
    TEMP_C=$(echo "scale=0; $TEMP_RAW / 100" | bc)
    sketchybar --set $NAME label="󰔏${TEMP_C}°"
else
    sketchybar --set $NAME label="󰔏--°"
fi
