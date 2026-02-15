------------------------------------------------------------
-- Scratchpad — Open fresh app windows via ⌃⌥⌘ (Scratch layer)
------------------------------------------------------------
local M = {}

local SCRIPT = os.getenv("HOME") .. "/.local/bin/scratchpad"

local bindings = {
    f = "Firefox",
    o = "Google Chrome",
    d = "Obsidian",
    s = "Spotify",
    b = "Bloom",
    q = "1Password",
}

function M.init()
    local mods = {"ctrl", "alt", "cmd"}
    for key, app in pairs(bindings) do
        hs.hotkey.bind(mods, key, function()
            hs.task.new(SCRIPT, nil, {app}):start()
        end)
    end
end

return M
