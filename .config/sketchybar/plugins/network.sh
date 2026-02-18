#!/bin/bash

# Network plugin - colour-only U/D, generous thresholds, sharp ramp
# Upload (U): 0/>0-1/1-10/10-50/50-80/80+ MB/s
# Download (D): 0/>0-5/5-20/20-80/80-150/150+ MB/s

source "$CONFIG_DIR/colours.sh" 2>/dev/null || exit 0

CACHE="/tmp/sketchybar_net"

STATS=$(netstat -ibn | awk '/Link/ && !/lo0/ {in+=$7; out+=$10} END {print in, out}')
IN_BYTES=$(echo "$STATS" | awk '{print $1}')
OUT_BYTES=$(echo "$STATS" | awk '{print $2}')

[[ -z "$IN_BYTES" || ! "$IN_BYTES" =~ ^[0-9]+$ ]] && IN_BYTES=0
[[ -z "$OUT_BYTES" || ! "$OUT_BYTES" =~ ^[0-9]+$ ]] && OUT_BYTES=0

NOW=$(date +%s 2>/dev/null) || NOW=0

# Upload tier (h = hundredths of MB/s)
up_tier() {
    local h=$1
    if [[ $h -ge 8000 ]]; then echo "$TIER_5"
    elif [[ $h -ge 5000 ]]; then echo "$TIER_4"
    elif [[ $h -ge 1000 ]]; then echo "$TIER_3"
    elif [[ $h -ge 100 ]]; then echo "$TIER_2"
    elif [[ $h -ge 1 ]]; then echo "$TIER_1"
    else echo "$TIER_0"; fi
}

# Download tier (h = hundredths of MB/s)
down_tier() {
    local h=$1
    if [[ $h -ge 15000 ]]; then echo "$TIER_5"
    elif [[ $h -ge 8000 ]]; then echo "$TIER_4"
    elif [[ $h -ge 2000 ]]; then echo "$TIER_3"
    elif [[ $h -ge 500 ]]; then echo "$TIER_2"
    elif [[ $h -ge 1 ]]; then echo "$TIER_1"
    else echo "$TIER_0"; fi
}

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

    DOWN_H=$((DOWN_RATE * 100 / 1048576))
    UP_H=$((UP_RATE * 100 / 1048576))

    down_color=$(down_tier $DOWN_H)
    up_color=$(up_tier $UP_H)

    # Active stats dim to 70%, idle to 20% (per-direction)
    if [[ -f /tmp/sketchybar_bar_faded ]]; then
        down_dim=$DIM_IDLE
        [[ "$down_color" != "$TIER_0" ]] && down_dim=$DIM_ACTIVE
        up_dim=$DIM_IDLE
        [[ "$up_color" != "$TIER_0" ]] && up_dim=$DIM_ACTIVE
        sketchybar --set net_down icon.color=$down_dim \
                   --set net_up icon.color=$up_dim 2>/dev/null
    else
        sketchybar --set net_down icon.color="$down_color" \
                   --set net_up icon.color="$up_color" 2>/dev/null
    fi
else
    sketchybar --set net_down icon.color="$TIER_0" \
               --set net_up icon.color="$TIER_0" 2>/dev/null
fi

echo "$IN_BYTES $OUT_BYTES $NOW" > "$CACHE" 2>/dev/null
