#!/bin/bash

# Delayed menu hide — runs detached from sketchybar's script lifecycle
STATEFILE="/tmp/sketchybar_menus_visible"
PIDFILE="/tmp/sketchybar_menu_hide.pid"

sleep 3

rm -f "$STATEFILE"
sketchybar \
    --set menu.0 label.drawing=off width=0 \
    --set menu.1 label.drawing=off width=0 \
    --set menu.2 label.drawing=off width=0 \
    --set menu.3 label.drawing=off width=0 \
    --set menu.4 label.drawing=off width=0 \
    --set menu.5 label.drawing=off width=0 \
    --set menu.6 label.drawing=off width=0 \
    --set menu.7 label.drawing=off width=0
rm -f "$PIDFILE"
