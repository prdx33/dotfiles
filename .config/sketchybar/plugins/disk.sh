#!/bin/bash

# Disk I/O plugin - colour-only R/W + disk_dot activity indicator
# Generous thresholds, sharp ramp at top
# Read (R): 0/>0-10/10-100/100-300/300-600/600+ MB/s
# Write (W): 0/>0-10/10-50/50-150/150-400/400+ MB/s
# Disk dot: ○ hollow idle, ● white normal, ● tiered at high I/O

source "$CONFIG_DIR/colours.sh" 2>/dev/null || exit 0

CACHE="/tmp/sketchybar_disk"

STATS=$(ioreg -c IOBlockStorageDriver -r -w 0 2>/dev/null | grep "Statistics" | grep -v '"Bytes (Read)"=0' | head -1)
READ_BYTES=$(echo "$STATS" | grep -oE '"Bytes \(Read\)"=[0-9]+' | grep -oE '[0-9]+' 2>/dev/null)
WRITE_BYTES=$(echo "$STATS" | grep -oE '"Bytes \(Write\)"=[0-9]+' | grep -oE '[0-9]+' 2>/dev/null)

[[ -z "$READ_BYTES" || ! "$READ_BYTES" =~ ^[0-9]+$ ]] && READ_BYTES=0
[[ -z "$WRITE_BYTES" || ! "$WRITE_BYTES" =~ ^[0-9]+$ ]] && WRITE_BYTES=0

NOW=$(date +%s 2>/dev/null) || NOW=0

read_tier() {
    local h=$1
    if [[ $h -ge 60000 ]]; then echo "$TIER_5"
    elif [[ $h -ge 30000 ]]; then echo "$TIER_4"
    elif [[ $h -ge 10000 ]]; then echo "$TIER_3"
    elif [[ $h -ge 1000 ]]; then echo "$TIER_2"
    elif [[ $h -ge 1 ]]; then echo "$TIER_1"
    else echo "$TIER_0"; fi
}

write_tier() {
    local h=$1
    if [[ $h -ge 40000 ]]; then echo "$TIER_5"
    elif [[ $h -ge 15000 ]]; then echo "$TIER_4"
    elif [[ $h -ge 5000 ]]; then echo "$TIER_3"
    elif [[ $h -ge 1000 ]]; then echo "$TIER_2"
    elif [[ $h -ge 1 ]]; then echo "$TIER_1"
    else echo "$TIER_0"; fi
}

if [[ -f "$CACHE" ]]; then
    read PREV_READ PREV_WRITE PREV_TIME < "$CACHE" 2>/dev/null
    [[ -z "$PREV_READ" ]] && PREV_READ=0
    [[ -z "$PREV_WRITE" ]] && PREV_WRITE=0
    [[ -z "$PREV_TIME" ]] && PREV_TIME=$NOW

    ELAPSED=$((NOW - PREV_TIME))
    [[ $ELAPSED -lt 1 ]] && ELAPSED=1

    READ_RATE=$(( (READ_BYTES - PREV_READ) / ELAPSED )) 2>/dev/null || READ_RATE=0
    WRITE_RATE=$(( (WRITE_BYTES - PREV_WRITE) / ELAPSED )) 2>/dev/null || WRITE_RATE=0

    [[ $READ_RATE -lt 0 ]] && READ_RATE=0
    [[ $WRITE_RATE -lt 0 ]] && WRITE_RATE=0

    READ_H=$((READ_RATE * 100 / 1048576))
    WRITE_H=$((WRITE_RATE * 100 / 1048576))

    r_color=$(read_tier $READ_H)
    w_color=$(write_tier $WRITE_H)

    # Disk dot: hollow idle, white normal, tiered at high combined I/O
    COMBINED=$((READ_H + WRITE_H))
    if [[ $COMBINED -ge 30000 ]]; then
        dot_icon="●"; dot_color=$TIER_4
    elif [[ $COMBINED -ge 10000 ]]; then
        dot_icon="●"; dot_color=$TIER_3
    elif [[ $COMBINED -ge 2000 ]]; then
        dot_icon="●"; dot_color=$TIER_2
    elif [[ $COMBINED -ge 1 ]]; then
        dot_icon="●"; dot_color=$TIER_0
    else
        dot_icon="●"; dot_color="0x66ffffff"
    fi

    # Active stats dim to 70%, idle to 20% (per-direction)
    if [[ -f /tmp/sketchybar_bar_faded ]]; then
        r_dim=$DIM_IDLE
        [[ "$r_color" != "$TIER_0" ]] && r_dim=$DIM_ACTIVE
        w_dim=$DIM_IDLE
        [[ "$w_color" != "$TIER_0" ]] && w_dim=$DIM_ACTIVE
        dot_dim=$DIM_IDLE
        [[ $COMBINED -ge 1 ]] && dot_dim=$DIM_ACTIVE
        sketchybar --set disk_read icon.color=$r_dim \
                   --set disk_write icon.color=$w_dim \
                   --set disk_dot icon.color=$dot_dim 2>/dev/null
    else
        sketchybar --set disk_read icon.color="$r_color" \
                   --set disk_write icon.color="$w_color" \
                   --set disk_dot icon="$dot_icon" icon.color="$dot_color" 2>/dev/null
    fi
else
    sketchybar --set disk_read icon.color="$TIER_0" \
               --set disk_write icon.color="$TIER_0" \
               --set disk_dot icon="●" icon.color="0x66ffffff" 2>/dev/null
fi

echo "$READ_BYTES $WRITE_BYTES $NOW" > "$CACHE" 2>/dev/null
