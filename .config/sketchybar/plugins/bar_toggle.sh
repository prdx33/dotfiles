#!/bin/bash

# Toggle sketchybar visibility
# Called by Hyper + ' keyboard shortcut

HIDDEN_FILE="/tmp/sketchybar_hidden"

if [[ -f "$HIDDEN_FILE" ]]; then
    # Currently hidden, show it
    sketchybar --bar hidden=off
    rm "$HIDDEN_FILE"
else
    # Currently visible, hide it
    sketchybar --bar hidden=on
    touch "$HIDDEN_FILE"
fi
