-- ~/.hammerspoon/windowManager.lua
local M = {}

-- Remember last minimised app
local lastMinimisedBundleID = nil

----------------------------------------------------
-- Minimise / Restore Toggle
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

----------------------------------------------------
-- Maximize / Fullscreen
----------------------------------------------------
M.toggleMaximize = function()
  local win = hs.window.focusedWindow()
  if not win then return end

  if win:isFullScreen() then
    win:setFullScreen(false)
  else
    win:setFullScreen(true)
  end
end

----------------------------------------------------
-- Center
----------------------------------------------------
M.centerWindow = function()
  local win = hs.window.focusedWindow()
  if not win then return end
  win:centerOnScreen()
end

----------------------------------------------------
-- Move to Next Screen
----------------------------------------------------
M.moveToNextScreen = function()
  local win = hs.window.focusedWindow()
  if not win then return end
  win:moveToScreen(win:screen():next(), true, true, 0)
end

----------------------------------------------------
-- Tiling (Spectacle-style)
----------------------------------------------------
M.leftHalf = function()
  local win = hs.window.focusedWindow()
  if win then win:moveToUnit(hs.layout.left50) end
end

M.rightHalf = function()
  local win = hs.window.focusedWindow()
  if win then win:moveToUnit(hs.layout.right50) end
end

M.topHalf = function()
  local win = hs.window.focusedWindow()
  if win then win:moveToUnit(hs.layout.top50) end
end

M.bottomHalf = function()
  local win = hs.window.focusedWindow()
  if win then win:moveToUnit(hs.layout.bottom50) end
end

M.topLeft = function()
  local win = hs.window.focusedWindow()
  if win then win:moveToUnit({0,0,0.5,0.5}) end
end

M.topRight = function()
  local win = hs.window.focusedWindow()
  if win then win:moveToUnit({0.5,0,1,0.5}) end
end

M.bottomLeft = function()
  local win = hs.window.focusedWindow()
  if win then win:moveToUnit({0,0.5,0.5,1}) end
end

M.bottomRight = function()
  local win = hs.window.focusedWindow()
  if win then win:moveToUnit({0.5,0.5,1,1}) end
end

M.maximize = function()
  local win = hs.window.focusedWindow()
  if win then win:maximize() end
end

return M