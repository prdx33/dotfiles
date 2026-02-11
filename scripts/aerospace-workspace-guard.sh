#!/bin/bash
# Workspace guard: bounce off numbered workspaces, update SketchyBar.
# Called by AeroSpace exec-on-workspace-change AND after-startup-command.

AE=/opt/homebrew/bin/aerospace
PREV="$AEROSPACE_PREV_WORKSPACE"
FOCUSED="$AEROSPACE_FOCUSED_WORKSPACE"
GUARD_LOCK="/tmp/aerospace_guard_bounce"

# Skip if we triggered this change (recursion from bounce)
if [[ -f "$GUARD_LOCK" ]]; then
    rm -f "$GUARD_LOCK"
    [[ -n "$FOCUSED" ]] && /opt/homebrew/bin/sketchybar --trigger aerospace_workspace_change \
        PREV="$PREV" FOCUSED="$FOCUSED"
    exit 0
fi

# Update SketchyBar
[[ -n "$FOCUSED" ]] && /opt/homebrew/bin/sketchybar --trigger aerospace_workspace_change \
    PREV="$PREV" FOCUSED="$FOCUSED"

# Flash workspace HUD
if [[ "$FOCUSED" =~ ^[A-Z]$ ]]; then
  WL=$($AE list-windows --focused --format '%{window-layout}' 2>/dev/null)
  /opt/homebrew/bin/hs -c "WorkspaceHUD:show('$FOCUSED','${WL:-}')" &
fi

# Bounce: if we landed on a numbered workspace, pin G to this orphaned monitor
if [[ "$FOCUSED" =~ ^[0-9]+$ ]]; then
    orphan_monitor=$($AE list-monitors --focused --format '%{monitor-id}' 2>/dev/null)
    target="G"
    # Rescue any stranded windows
    for wid in $($AE list-windows --workspace "$FOCUSED" --format '%{window-id}' 2>/dev/null); do
        [[ -n "$wid" ]] && $AE move-node-to-workspace --window-id "$wid" "$target" 2>/dev/null
    done
    touch "$GUARD_LOCK"
    $AE move-workspace-to-monitor --workspace "$target" "$orphan_monitor" 2>/dev/null
    $AE workspace "$target" 2>/dev/null
fi
