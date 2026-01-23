#!/bin/bash

# CPU plugin

cpu_line=$(top -l 1 -n 0 2>/dev/null | grep "CPU usage")
user=$(echo "$cpu_line" | awk '{print $3}' | tr -d '%')
sys=$(echo "$cpu_line" | awk '{print $5}' | tr -d '%')

cpu=$(echo "$user + $sys" | bc | cut -d. -f1)
[[ -z "$cpu" ]] && cpu=0

graph_val=$(echo "scale=2; $cpu / 100" | bc)
[[ $(echo "$graph_val > 1" | bc) -eq 1 ]] && graph_val=1

sketchybar --set $NAME label="CPU ${cpu}%" --push $NAME $graph_val
