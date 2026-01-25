#!/bin/bash

# NextDNS status plugin
# White when active, red when inactive

source "$CONFIG_DIR/colours.sh"

# Check if NextDNS app is running and routing DNS
if pgrep -q "NextDNS"; then
    dns_server=$(scutil --dns 2>/dev/null | grep "nameserver\[0\]" | head -1 | awk '{print $3}')
    if [[ "$dns_server" == 127.* ]]; then
        sketchybar --set $NAME icon.color="$DNS_ACTIVE"
    else
        sketchybar --set $NAME icon.color="$DNS_INACTIVE"
    fi
else
    sketchybar --set $NAME icon.color="$DNS_INACTIVE"
fi
