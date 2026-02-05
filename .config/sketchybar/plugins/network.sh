#!/bin/bash

# Network plugin using netstat cumulative bytes + cache delta
# Instant (~2ms) instead of ifstat blocking (~108ms)

source "$CONFIG_DIR/colours.sh" 2>/dev/null || exit 0

CACHE="/tmp/sketchybar_net"

# Get cumulative bytes from netstat (instant, no sampling delay)
STATS=$(netstat -ibn | awk '/en0.*Link/{print $7, $10}')
IN_BYTES=$(echo "$STATS" | awk '{print $1}')
OUT_BYTES=$(echo "$STATS" | awk '{print $2}')

[[ -z "$IN_BYTES" || ! "$IN_BYTES" =~ ^[0-9]+$ ]] && IN_BYTES=0
[[ -z "$OUT_BYTES" || ! "$OUT_BYTES" =~ ^[0-9]+$ ]] && OUT_BYTES=0

NOW=$(date +%s 2>/dev/null) || NOW=0

if [[ -f "$CACHE" ]]; then
    read PREV_IN PREV_OUT PREV_TIME < "$CACHE" 2>/dev/null
    [[ -z "$PREV_IN" ]] && PREV_IN=0
    [[ -z "$PREV_OUT" ]] && PREV_OUT=0
    [[ -z "$PREV_TIME" ]] && PREV_TIME=$NOW

    ELAPSED=$((NOW - PREV_TIME))
    [[ $ELAPSED -lt 1 ]] && ELAPSED=1

    DOWN_RATE=$(( (IN_BYTES - PREV_IN) / ELAPSED )) 2>/dev/null || DOWN_RATE=0
    UP_RATE=$(( (OUT_BYTES - PREV_OUT) / ELAPSED )) 2>/dev/null || UP_RATE=0

    [[ $DOWN_RATE -lt 0 ]] && DOWN_RATE=0
    [[ $UP_RATE -lt 0 ]] && UP_RATE=0

    # Convert bytes/s to MB/s using integer math (no bc)
    DOWN_H=$((DOWN_RATE * 100 / 1048576))
    UP_H=$((UP_RATE * 100 / 1048576))

    DOWN_FMT=$(printf "%2d.%02dMB" $((DOWN_H / 100)) $((DOWN_H % 100)))
    UP_FMT=$(printf "%2d.%02dMB" $((UP_H / 100)) $((UP_H % 100)))

    sketchybar --set net_down label="$DOWN_FMT" \
               --set net_up label="$UP_FMT" 2>/dev/null
else
    sketchybar --set net_down label=" 0.00MB" \
               --set net_up label=" 0.00MB" 2>/dev/null
fi

echo "$IN_BYTES $OUT_BYTES $NOW" > "$CACHE" 2>/dev/null
