#!/bin/bash
# Swap visible workspaces between monitors (cycle for 2+)

current_ws=$(/opt/homebrew/bin/aerospace list-workspaces --focused)
monitor1_ws=$(/opt/homebrew/bin/aerospace list-workspaces --monitor 1 --visible)
monitor2_ws=$(/opt/homebrew/bin/aerospace list-workspaces --monitor 2 --visible)
current_monitor=$(/opt/homebrew/bin/aerospace list-monitors --focused | awk '{print $1}')

if [[ "$current_monitor" == "1" ]]; then
    other_ws="$monitor2_ws"
else
    other_ws="$monitor1_ws"
fi

# Summon other workspace here, switch back to ours, push ours across, focus swapped
/opt/homebrew/bin/aerospace summon-workspace "$other_ws"
/opt/homebrew/bin/aerospace workspace "$current_ws"
/opt/homebrew/bin/aerospace move-workspace-to-monitor --wrap-around next
/opt/homebrew/bin/aerospace workspace "$other_ws"
