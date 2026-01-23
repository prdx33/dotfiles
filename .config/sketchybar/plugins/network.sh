#!/bin/bash

# Network plugin - updates net_down and net_up items

CACHE="/tmp/sketchybar_net"

# Get current bytes
for iface in en0 en1 en4; do
    bytes=$(netstat -ib | awk -v iface="$iface" '$1==iface && $3~/Link/ {print $7, $10; exit}')
    [[ -n "$bytes" ]] && break
done
read rx tx <<< "$bytes"

if [[ -f "$CACHE" && -n "$rx" ]]; then
    read prev_rx prev_tx prev_time < "$CACHE"
    now=$(date +%s)
    elapsed=$((now - prev_time))
    [[ $elapsed -lt 1 ]] && elapsed=1

    rx_rate=$(( (rx - prev_rx) / elapsed / 1024 ))
    tx_rate=$(( (tx - prev_tx) / elapsed / 1024 ))
    [[ $rx_rate -lt 0 ]] && rx_rate=0
    [[ $tx_rate -lt 0 ]] && tx_rate=0

    # Format
    if [[ $rx_rate -ge 1024 ]]; then
        rx_fmt="$(echo "scale=1; $rx_rate/1024" | bc)M"
    else
        rx_fmt="${rx_rate}K"
    fi
    if [[ $tx_rate -ge 1024 ]]; then
        tx_fmt="$(echo "scale=1; $tx_rate/1024" | bc)M"
    else
        tx_fmt="${tx_rate}K"
    fi

    sketchybar --set net_down label="$rx_fmt" --set net_up label="$tx_fmt"
else
    sketchybar --set net_down label="0K" --set net_up label="0K"
fi

[[ -n "$rx" ]] && echo "$rx $tx $(date +%s)" > "$CACHE"
