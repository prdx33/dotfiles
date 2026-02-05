#!/bin/bash

# Front app plugin - shows the focused/active app on specific monitor

monitor="$1"

# On system wake, add delay to prevent fork bomb
if [[ "$SENDER" == "system_woke" ]]; then
    sleep 2
fi

# Get visible workspace on this monitor
ws=$(aerospace list-workspaces --monitor "$monitor" --visible 2>/dev/null)

app=""
if [[ -n "$ws" ]]; then
    # Get windows on this workspace
    windows=$(aerospace list-windows --workspace "$ws" 2>/dev/null)

    if [[ -n "$windows" ]]; then
        # Get globally focused window
        focused_wid=$(aerospace list-windows --focused 2>/dev/null | cut -d'|' -f1 | xargs)

        # Check if focused window is on this workspace
        while IFS='|' read -r wid app_name title; do
            wid_clean=$(echo "$wid" | xargs)
            if [[ "$wid_clean" == "$focused_wid" ]]; then
                app=$(echo "$app_name" | xargs)
                break
            fi
        done <<< "$windows"

        # If focused window not on this workspace, use first window's app
        if [[ -z "$app" ]]; then
            app=$(echo "$windows" | head -1 | cut -d'|' -f2 | xargs)
        fi
    fi
fi

# ALL CAPS
app_upper=$(echo "$app" | tr '[:lower:]' '[:upper:]')
sketchybar --set "$NAME" label="$app_upper" 2>/dev/null
