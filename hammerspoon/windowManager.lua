-- ~/.hammerspoon/windowManager.lua
-- Minimise/restore toggle for the focused window
local M = {}

-- Remember last minimised app
local lastMinimisedBundleID = nil

----------------------------------------------------
-- Minimise / Restore Toggle (⌘M)
----------------------------------------------------
M.toggleMinimize = function()
  local win = hs.window.focusedWindow()

  if win and not win:isMinimized() then
    local app = win:application()
    if app then lastMinimisedBundleID = app:bundleID() end
    win:minimize()
    return
  end

  local targetApp = nil
  if lastMinimisedBundleID then
    targetApp = hs.application.get(lastMinimisedBundleID)
  end
  if not targetApp then
    targetApp = hs.application.frontmostApplication()
  end
  if not targetApp then return end

  local restored = false
  for _, w in ipairs(targetApp:allWindows()) do
    if w:isMinimized() then
      w:unminimize()
      if not restored then
        w:focus()
        restored = true
      end
    end
  end

  if restored then lastMinimisedBundleID = nil end
end

return M
