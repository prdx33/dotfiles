#!/bin/bash

# Disk I/O plugin - updates disk_read and disk_write items

CACHE="/tmp/sketchybar_disk"

# Get disk stats from iostat
read_bytes=$(iostat -c 1 disk0 2>/dev/null | tail -1 | awk '{print $3}')
write_bytes=$(iostat -c 1 disk0 2>/dev/null | tail -1 | awk '{print $4}')

# Format (iostat gives KB/s)
if [[ -n "$read_bytes" && "$read_bytes" =~ ^[0-9.]+$ ]]; then
    read_kb=$(echo "$read_bytes" | cut -d. -f1)
    if [[ $read_kb -ge 1024 ]]; then
        read_fmt="$(echo "scale=1; $read_kb/1024" | bc)M"
    else
        read_fmt="${read_kb}K"
    fi
else
    read_fmt="0K"
fi

if [[ -n "$write_bytes" && "$write_bytes" =~ ^[0-9.]+$ ]]; then
    write_kb=$(echo "$write_bytes" | cut -d. -f1)
    if [[ $write_kb -ge 1024 ]]; then
        write_fmt="$(echo "scale=1; $write_kb/1024" | bc)M"
    else
        write_fmt="${write_kb}K"
    fi
else
    write_fmt="0K"
fi

sketchybar --set disk_read label="$read_fmt" --set disk_write label="$write_fmt"
