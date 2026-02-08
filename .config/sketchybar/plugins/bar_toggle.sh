#!/bin/bash

# Toggle sketchybar visibility — called directly from Karabiner (no Hammerspoon hop)

HIDDEN_FILE="/tmp/sketchybar_hidden"
SKETCHYBAR="/opt/homebrew/bin/sketchybar"

if [[ -f "$HIDDEN_FILE" ]]; then
    $SKETCHYBAR --bar hidden=off
    rm "$HIDDEN_FILE"
else
    $SKETCHYBAR --bar hidden=on
    touch "$HIDDEN_FILE"
fi
