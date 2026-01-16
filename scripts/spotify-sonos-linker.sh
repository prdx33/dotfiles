#!/bin/bash
#
# spotify-sonos-linker.sh
# Launches Menu Bar Controller for Sonos 2 when Spotify opens,
# and closes it when Spotify quits.
#

SPOTIFY_APP="Spotify"
SONOS_APP="Menu Bar Controller for Sonos 2"
SONOS_PROCESS="Menu Bar Controller for Sonos"  # Process name differs from app name

# Track previous state to avoid repeated open/close attempts
spotify_was_running=false

# Check if an app is running by process name
is_running() {
    pgrep -xq "$1"
}

# Main monitoring loop
while true; do
    if is_running "$SPOTIFY_APP"; then
        # Spotify is running
        if [ "$spotify_was_running" = false ]; then
            # Spotify just launched - open Sonos controller
            if ! is_running "$SONOS_PROCESS"; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Spotify detected, launching Sonos controller"
                open -a "$SONOS_APP"
            fi
            spotify_was_running=true
        fi
    else
        # Spotify is not running
        if [ "$spotify_was_running" = true ]; then
            # Spotify just closed - quit Sonos controller
            if is_running "$SONOS_PROCESS"; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Spotify closed, quitting Sonos controller"
                osascript -e "quit app \"$SONOS_APP\""
            fi
            spotify_was_running=false
        fi
    fi

    # Check every 2 seconds
    sleep 2
done
