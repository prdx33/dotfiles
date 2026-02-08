#!/bin/bash

# Toggle menu items visibility with delayed hide
PIDFILE="/tmp/sketchybar_menu_hide.pid"

show_menus() {
    # Cancel any pending hide
    if [[ -f "$PIDFILE" ]]; then
        kill "$(cat "$PIDFILE")" 2>/dev/null
        rm -f "$PIDFILE"
    fi

    sketchybar \
        --set menu.0 label.drawing=on label.padding_left=9 label.padding_right=11 width=dynamic \
        --set menu.1 label.drawing=on label.padding_left=9 label.padding_right=11 width=dynamic \
        --set menu.2 label.drawing=on label.padding_left=9 label.padding_right=11 width=dynamic \
        --set menu.3 label.drawing=on label.padding_left=9 label.padding_right=11 width=dynamic \
        --set menu.4 label.drawing=on label.padding_left=9 label.padding_right=11 width=dynamic \
        --set menu.5 label.drawing=on label.padding_left=9 label.padding_right=11 width=dynamic \
        --set menu.6 label.drawing=on label.padding_left=9 label.padding_right=11 width=dynamic \
        --set menu.7 label.drawing=on label.padding_left=9 label.padding_right=11 width=dynamic
}

hide_menus() {
    # Cancel any existing timer
    if [[ -f "$PIDFILE" ]]; then
        kill "$(cat "$PIDFILE")" 2>/dev/null
        rm -f "$PIDFILE"
    fi

    (
        sleep 1.5
        sketchybar \
            --set menu.0 label.drawing=off label.padding_left=0 label.padding_right=0 width=0 \
            --set menu.1 label.drawing=off label.padding_left=0 label.padding_right=0 width=0 \
            --set menu.2 label.drawing=off label.padding_left=0 label.padding_right=0 width=0 \
            --set menu.3 label.drawing=off label.padding_left=0 label.padding_right=0 width=0 \
            --set menu.4 label.drawing=off label.padding_left=0 label.padding_right=0 width=0 \
            --set menu.5 label.drawing=off label.padding_left=0 label.padding_right=0 width=0 \
            --set menu.6 label.drawing=off label.padding_left=0 label.padding_right=0 width=0 \
            --set menu.7 label.drawing=off label.padding_left=0 label.padding_right=0 width=0
        rm -f "$PIDFILE"
    ) &
    echo $! > "$PIDFILE"
}

case "$SENDER" in
    mouse.entered) show_menus ;;
    mouse.exited) hide_menus ;;
esac
