#!/bin/bash

# Menu bar plugin - displays current app's menu items as clickable items

MAX_MENUS=8

# Get frontmost app name and menu items
OUTPUT=$(osascript -e '
tell application "System Events"
    try
        set frontApp to first application process whose frontmost is true
        set appName to name of frontApp
        set menuItems to name of every menu bar item of menu bar 1 of frontApp
        set output to ""
        repeat with i from 3 to count of menuItems
            set menuName to item i of menuItems
            if menuName is not missing value and menuName is not "" then
                if output is "" then
                    set output to menuName
                else
                    set output to output & "|" & menuName
                end if
            end if
        end repeat
        return appName & "|||" & output
    on error
        return "|||"
    end try
end tell
' 2>/dev/null)

# Parse
APP_NAME="${OUTPUT%%|||*}"
MENU_LIST="${OUTPUT#*|||}"

# Save to temp file to avoid subshell issues
TMPFILE="/tmp/sketchybar_menus_$$"
echo "$MENU_LIST" | tr '|' '\n' > "$TMPFILE"

i=0
while read -r menu_name && [[ $i -lt $MAX_MENUS ]]; do
    menu_name=$(echo "$menu_name" | xargs)
    if [[ -n "$menu_name" ]]; then
        # Store original for click, display uppercase
        menu_upper=$(echo "$menu_name" | tr '[:lower:]' '[:upper:]')
        sketchybar --set "menu.$i" \
            label="$menu_upper" \
            label.drawing=on \
            click_script="osascript -e 'tell application \"System Events\" to tell process \"$APP_NAME\" to click menu bar item \"$menu_name\" of menu bar 1'" \
            2>/dev/null
    fi
    i=$((i + 1))
done < "$TMPFILE"

# Hide unused slots
while [[ $i -lt $MAX_MENUS ]]; do
    sketchybar --set "menu.$i" label="" label.drawing=off 2>/dev/null
    i=$((i + 1))
done

rm -f "$TMPFILE"
