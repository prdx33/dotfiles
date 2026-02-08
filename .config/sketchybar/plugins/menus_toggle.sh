#!/bin/bash

# Toggle menu items visibility — hover in/out with 3s delayed hide
# State tracking prevents redundant redraws that cause flickering
STATEFILE="/tmp/sketchybar_menus_visible"
PIDFILE="/tmp/sketchybar_menu_hide.pid"
HIDE_SCRIPT="$HOME/.config/sketchybar/plugins/menus_hide.sh"

cancel_hide() {
    if [[ -f "$PIDFILE" ]]; then
        kill "$(cat "$PIDFILE")" 2>/dev/null
        rm -f "$PIDFILE"
    fi
}

show_menus() {
    cancel_hide

    # Skip if already visible — prevents flicker from redundant redraws
    [[ -f "$STATEFILE" ]] && return

    touch "$STATEFILE"
    sketchybar \
        --set menu.0 label.drawing=on width=dynamic \
        --set menu.1 label.drawing=on width=dynamic \
        --set menu.2 label.drawing=on width=dynamic \
        --set menu.3 label.drawing=on width=dynamic \
        --set menu.4 label.drawing=on width=dynamic \
        --set menu.5 label.drawing=on width=dynamic \
        --set menu.6 label.drawing=on width=dynamic \
        --set menu.7 label.drawing=on width=dynamic
}

hide_menus() {
    cancel_hide

    # Detached process — survives script exit
    nohup bash "$HIDE_SCRIPT" </dev/null >/dev/null 2>&1 &
    echo $! > "$PIDFILE"
}

case "$SENDER" in
    mouse.entered) show_menus ;;
    mouse.exited) hide_menus ;;
esac
