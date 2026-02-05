#!/bin/zsh
# Move workspace to the monitor where mouse is (where user clicked)
# $1 = workspace ID

ws="$1"

# Use Hammerspoon to get mouse screen (already running)
display=$(hs -c "return hs.mouse.getCurrentScreen():id()" 2>/dev/null)

# Map screen ID to aerospace monitor number (1 or 2)
# Get aerospace monitor list and match
if [[ -n "$display" ]]; then
    # Aerospace uses 1-indexed monitor numbers
    # Check which monitor the mouse is on by comparing to focused monitor
    m1_bounds=$(hs -c "local s = hs.screen.find(1); if s then return s:frame().x else return 0 end" 2>/dev/null)
    mouse_x=$(hs -c "return hs.mouse.absolutePosition().x" 2>/dev/null)

    # Simple: if mouse X is less than screen 2's origin, it's on monitor 1
    # For now, let's just use Hammerspoon's screen index
    screen_index=$(hs -c "
        local screens = hs.screen.allScreens()
        local mouseScreen = hs.mouse.getCurrentScreen()
        for i, s in ipairs(screens) do
            if s == mouseScreen then return i end
        end
        return 1
    " 2>/dev/null)
    display="${screen_index:-1}"
fi

display="${display:-1}"

/opt/homebrew/bin/aerospace move-workspace-to-monitor --workspace "$ws" "$display" 2>/dev/null
/opt/homebrew/bin/aerospace workspace "$ws" 2>/dev/null
