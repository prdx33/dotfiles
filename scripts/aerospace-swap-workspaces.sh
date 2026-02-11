#!/bin/bash
# Swap visible workspaces between monitors.
# Avoids summon-workspace (creates numbered placeholders in 0.20.x).
# Uses move-workspace-to-monitor, moving FROM monitor 1 first since it
# always has many parked workspaces and won't trigger a placeholder.

AE=/opt/homebrew/bin/aerospace

m1_ws=$($AE list-workspaces --monitor 1 --visible)
m2_ws=$($AE list-workspaces --monitor 2 --visible)

# Bail if only one monitor connected
[[ -z "$m1_ws" || -z "$m2_ws" ]] && exit 0

focused_monitor=$($AE list-monitors --focused | awk '{print $1}')

# Step 1: Send M1's workspace to M2 (M1 has many workspaces — safe to lose one)
$AE workspace "$m1_ws"
$AE move-workspace-to-monitor --wrap-around next

# Step 2: Send M2's original workspace to M1 (M2 now has m1_ws — safe to lose m2_ws)
$AE workspace "$m2_ws"
$AE move-workspace-to-monitor --wrap-around next

# Step 3: Focus the swapped-in workspace on the user's original monitor
if [[ "$focused_monitor" == "1" ]]; then
    $AE workspace "$m2_ws"
else
    $AE workspace "$m1_ws"
fi

# Step 4: Tile all windows on both monitors so they auto-fit the new screen
tile_ws() {
    for wid in $($AE list-windows --workspace "$1" --format '%{window-id}'); do
        $AE layout --window-id "$wid" tiling 2>/dev/null
    done
}
tile_ws "$m2_ws"
tile_ws "$m1_ws"

# Step 5: Force clean SketchyBar refresh (swap causes rapid workspace changes
# that leave stale highlights from intermediate states)
/opt/homebrew/bin/sketchybar --trigger space_change
