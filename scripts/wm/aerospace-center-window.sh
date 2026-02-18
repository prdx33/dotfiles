#!/bin/bash
# Center a window via Rectangle, but only once per window ID.
# Prevents modals/dialogs from re-centering parent windows.
# Called by aerospace on-window-detected.

CACHE="/tmp/aerospace-centered-windows"

# Get focused window ID
WINDOW_ID=$(aerospace list-windows --focused --json 2>/dev/null \
  | sed -n 's/.*"window-id" *: *\([0-9]*\).*/\1/p')

[[ -z "$WINDOW_ID" ]] && exit 0

# Skip if already centered
grep -qx "$WINDOW_ID" "$CACHE" 2>/dev/null && exit 0

# Record and center
echo "$WINDOW_ID" >> "$CACHE"
open -g "rectangle://execute-action?name=center"
