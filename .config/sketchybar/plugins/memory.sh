#!/bin/bash

# Memory plugin - "MEM XX%" format

mem_free=$(memory_pressure 2>/dev/null | grep "System-wide memory free percentage" | awk '{print $5}' | tr -d '%')
[[ -z "$mem_free" ]] && mem_free=50

mem_used=$((100 - mem_free))

graph_val=$(echo "scale=2; $mem_used / 100" | bc)

sketchybar --set $NAME label="MEM ${mem_used}%" --push $NAME $graph_val
