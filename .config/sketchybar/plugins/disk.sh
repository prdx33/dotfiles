#!/bin/bash

# Disk I/O plugin using ioreg
# Fixed width format: "R XXX.XX MB" (11 chars total)

CACHE="/tmp/sketchybar_disk"

# Get cumulative bytes from ioreg
STATS=$(ioreg -c IOBlockStorageDriver -r -w 0 2>/dev/null | grep "Statistics" | grep -v '"Bytes (Read)"=0' | head -1)
READ_BYTES=$(echo "$STATS" | grep -oE '"Bytes \(Read\)"=[0-9]+' | grep -oE '[0-9]+' 2>/dev/null)
WRITE_BYTES=$(echo "$STATS" | grep -oE '"Bytes \(Write\)"=[0-9]+' | grep -oE '[0-9]+' 2>/dev/null)

[[ -z "$READ_BYTES" || ! "$READ_BYTES" =~ ^[0-9]+$ ]] && READ_BYTES=0
[[ -z "$WRITE_BYTES" || ! "$WRITE_BYTES" =~ ^[0-9]+$ ]] && WRITE_BYTES=0

NOW=$(date +%s 2>/dev/null) || NOW=0

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

    # Convert bytes/s to MB/s
    READ_MB=$(echo "scale=2; $READ_RATE / 1048576" | bc 2>/dev/null) || READ_MB="0.00"
    WRITE_MB=$(echo "scale=2; $WRITE_RATE / 1048576" | bc 2>/dev/null) || WRITE_MB="0.00"

    [[ -z "$READ_MB" ]] && READ_MB="0.00"
    [[ -z "$WRITE_MB" ]] && WRITE_MB="0.00"

    READ_FMT=$(printf "%5.2fMB" "$READ_MB")
    WRITE_FMT=$(printf "%5.2fMB" "$WRITE_MB")

    sketchybar --set disk_read label="$READ_FMT" \
               --set disk_write label="$WRITE_FMT" 2>/dev/null
else
    sketchybar --set disk_read label="0.00MB" \
               --set disk_write label="0.00MB" 2>/dev/null
fi

echo "$READ_BYTES $WRITE_BYTES $NOW" > "$CACHE" 2>/dev/null
