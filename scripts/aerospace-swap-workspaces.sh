#!/bin/bash
# aerospace-swap-workspaces.sh
# Swap workspaces between monitors

# Debug log
echo "$(date): swap started" >> /tmp/aerospace-swap.log

# Capture state BEFORE any changes
current_ws=$(aerospace list-workspaces --focused)
monitor1_ws=$(aerospace list-workspaces --monitor 1 --visible)
monitor2_ws=$(aerospace list-workspaces --monitor 2 --visible)
current_monitor=$(aerospace list-monitors --focused | awk '{print $1}')

# Determine which workspace is on the other monitor
if [[ "$current_monitor" == "1" ]]; then
    other_ws="$monitor2_ws"
else
    other_ws="$monitor1_ws"
fi

# Step 1: Summon the other workspace here (now both are on this monitor)
aerospace summon-workspace "$other_ws"

# Step 2: Switch back to original workspace (still on this monitor, just hidden)
aerospace workspace "$current_ws"

# Step 3: Move it to the other monitor
aerospace move-workspace-to-monitor --wrap-around next

# Step 4: Focus back on the summoned workspace (now alone on original monitor)
aerospace workspace "$other_ws"

echo "$(date): swap done - was on M${current_monitor}, swapped ${current_ws} with ${other_ws}" >> /tmp/aerospace-swap.log
