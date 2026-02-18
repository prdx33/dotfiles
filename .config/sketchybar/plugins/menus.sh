#!/bin/bash

# Menu bar plugin - displays current app's menu items as clickable items

MAX_MENUS=14

# Get frontmost app name and menu items
OUTPUT=$(osascript -e '
tell application "System Events"
    try
        set frontApp to first application process whose frontmost is true
        set procName to name of frontApp
        set dispName to displayed name of frontApp
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
        return procName & "|||" & dispName & "|||" & output
    on error
        return "||||||"
    end try
end tell
' 2>/dev/null)

# Parse: PROC_NAME|||DISPLAY_NAME|||MENUS
PROC_NAME="${OUTPUT%%|||*}"
REST="${OUTPUT#*|||}"
DISPLAY_NAME="${REST%%|||*}"
MENU_LIST="${REST#*|||}"

# Update app name item (uppercase) - use display name for label
if [[ -n "$DISPLAY_NAME" ]]; then
    APP_UPPER=$(echo "$DISPLAY_NAME" | tr '[:lower:]' '[:upper:]')
    sketchybar --set app_name label="$APP_UPPER"
fi

# Save to temp file to avoid subshell issues
TMPFILE="/tmp/sketchybar_menus_$$"
echo "$MENU_LIST" | tr '|' '\n' > "$TMPFILE"

# Respect hard toggle state
MENUS_HIDDEN=0
[[ -f "/tmp/sketchybar_menus_hidden" ]] && MENUS_HIDDEN=1

i=0
while read -r menu_name && [[ $i -lt $MAX_MENUS ]]; do
    menu_name=$(echo "$menu_name" | xargs)
    if [[ -n "$menu_name" ]]; then
        menu_upper=$(echo "$menu_name" | tr '[:lower:]' '[:upper:]')
        if [[ $MENUS_HIDDEN -eq 1 ]]; then
            drawing=off; w=0
        else
            drawing=on; w=dynamic
        fi
        sketchybar --set "menu.$i" \
            label="$menu_upper" \
            label.drawing=$drawing \
            width=$w \
            click_script="osascript -e 'tell application \"System Events\" to tell process \"$PROC_NAME\" to click menu bar item \"$menu_name\" of menu bar 1'" \
            2>/dev/null
    fi
    i=$((i + 1))
done < "$TMPFILE"

# Clear unused slots
while [[ $i -lt $MAX_MENUS ]]; do
    sketchybar --set "menu.$i" label="" label.drawing=off width=0 2>/dev/null
    i=$((i + 1))
done

rm -f "$TMPFILE"
