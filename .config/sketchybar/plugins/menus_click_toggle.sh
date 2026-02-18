#!/bin/bash

# Hard toggle menu items on app_icon click
# Persists state in /tmp so menus stay hidden/shown until clicked again

STATEFILE="/tmp/sketchybar_menus_hidden"
MAX_MENUS=14

if [[ -f "$STATEFILE" ]]; then
    # Currently hidden → show
    rm -f "$STATEFILE"
    for i in $(seq 0 $((MAX_MENUS - 1))); do
        sketchybar --set "menu.$i" label.drawing=on width=dynamic 2>/dev/null
    done
else
    # Currently visible → hide
    touch "$STATEFILE"
    for i in $(seq 0 $((MAX_MENUS - 1))); do
        sketchybar --set "menu.$i" label.drawing=off width=0 2>/dev/null
    done
fi
