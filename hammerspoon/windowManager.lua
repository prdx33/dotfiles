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

----------------------------------------------------
-- Alt+Shift Click-Drag to Move Window
----------------------------------------------------
local dragging = false
local dragWindow = nil
local dragOffset = { x = 0, y = 0 }

M.mouseDragWatcher = hs.eventtap.new(
  { hs.eventtap.event.types.leftMouseDown,
    hs.eventtap.event.types.leftMouseDragged,
    hs.eventtap.event.types.leftMouseUp },
  function(e)
    local flags = e:getFlags()
    local altShift = flags.alt and flags.shift and not flags.cmd and not flags.ctrl

    if e:getType() == hs.eventtap.event.types.leftMouseDown then
      if altShift then
        local mousePos = hs.mouse.absolutePosition()
        local win = hs.window.focusedWindow()
        if not win then
          -- Try to find window under mouse
          local wins = hs.window.orderedWindows()
          for _, w in ipairs(wins) do
            local f = w:frame()
            if mousePos.x >= f.x and mousePos.x <= f.x + f.w and
               mousePos.y >= f.y and mousePos.y <= f.y + f.h then
              win = w
              break
            end
          end
        end
        if win then
          dragging = true
          dragWindow = win
          local wf = win:frame()
          dragOffset.x = mousePos.x - wf.x
          dragOffset.y = mousePos.y - wf.y
          return true
        end
      end
    elseif e:getType() == hs.eventtap.event.types.leftMouseDragged then
      if dragging and dragWindow then
        local mousePos = hs.mouse.absolutePosition()
        local wf = dragWindow:frame()
        wf.x = mousePos.x - dragOffset.x
        wf.y = mousePos.y - dragOffset.y
        dragWindow:setFrame(wf, 0)
        return true
      end
    elseif e:getType() == hs.eventtap.event.types.leftMouseUp then
      if dragging then
        dragging = false
        dragWindow = nil
        return true
      end
    end
    return false
  end
)

M.mouseDragWatcher:start()

return M