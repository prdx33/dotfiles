------------------------------------------------------------
-- Bar Toggle - Flip between SketchyBar and macOS menu bar
--
-- Since SketchyBar has topmost=on, it covers the native bar.
-- We just toggle SketchyBar visibility - native bar is always there underneath.
------------------------------------------------------------

local BarToggle = {}

-- State: true = SketchyBar visible, false = macOS menu bar visible
BarToggle.sketchybarVisible = true

function BarToggle:toggle()
    if self.sketchybarVisible then
        -- Hide SketchyBar → reveals macOS menu bar underneath
        hs.execute("sketchybar --bar hidden=true", true)
        self.sketchybarVisible = false
        hs.alert.show("macOS Menu Bar", 0.3)
    else
        -- Show SketchyBar → covers macOS menu bar
        hs.execute("sketchybar --bar hidden=false", true)
        self.sketchybarVisible = true
        hs.alert.show("SketchyBar", 0.3)
    end
end

-- Query actual state on load (in case SketchyBar was toggled externally)
function BarToggle:syncState()
    local output = hs.execute("sketchybar --query bar | grep -o '\"hidden\":[^,]*' | cut -d: -f2", true)
    if output then
        local hidden = output:match("true")
        self.sketchybarVisible = not hidden
    end
end

function BarToggle:init()
    self:syncState()
    print("[BarToggle] Ready (SketchyBar " .. (self.sketchybarVisible and "visible" or "hidden") .. ")")
end

return BarToggle
