#!/bin/bash

# GPU plugin - "GPU XX%" format

gpu=$(ioreg -r -d 1 -c IOAccelerator 2>/dev/null | grep -o '"Device Utilization %"=[0-9]*' | grep -o '[0-9]*' | head -1)
[[ -z "$gpu" ]] && gpu=0

graph_val=$(echo "scale=2; $gpu / 100" | bc)

sketchybar --set $NAME label="GPU ${gpu}%" --push $NAME $graph_val
