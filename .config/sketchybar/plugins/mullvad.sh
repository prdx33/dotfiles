#!/bin/bash

# Mullvad VPN status plugin
# White when connected, red when disconnected

source "$CONFIG_DIR/colours.sh"

mullvad_stat=$(mullvad status 2>/dev/null | head -1)

if [[ "$mullvad_stat" == "Connected" ]]; then
    sketchybar --set $NAME icon.color="$VPN_ACTIVE"
else
    sketchybar --set $NAME icon.color="$VPN_INACTIVE"
fi
