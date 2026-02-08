#!/bin/zsh
# Focus next monitor and move mouse to center of focused window

/opt/homebrew/bin/aerospace focus-monitor --wrap-around next

# Brief delay for focus to complete
sleep 0.05

# Move mouse to center of now-focused window using AppleScript
osascript -e '
tell application "System Events"
    set frontProc to first process whose frontmost is true
    tell frontProc
        try
            set {x, y} to position of front window
            set {w, h} to size of front window
            set newX to x + (w / 2)
            set newY to y + (h / 2)
        on error
            return
        end try
    end tell
end tell

tell application "System Events"
    set mouseLocation to {newX, newY}
end tell

-- Use Python to move the mouse (built-in on macOS)
do shell script "python3 -c \"
import Quartz
Quartz.CGWarpMouseCursorPosition((" & newX & ", " & newY & "))
Quartz.CGAssociateMouseAndMouseCursorPosition(True)
\""
'
