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
-- Cmd+Option Hold-to-Move / Cmd+Option+Shift Hold-to-Resize
-- Hold Cmd+Option to drag window under cursor
-- Hold Cmd+Option+Shift to resize window
----------------------------------------------------
local holdState = {
  mode = nil,  -- nil, "move", or "resize"
  window = nil,
  initialMousePos = nil,
  initialFrame = nil,
  lastUpdate = 0,
}

-- Throttle interval in nanoseconds (~60fps) - balanced smoothness vs GPU load
local THROTTLE_NS = 16000000  -- 16ms in nanoseconds
local MIN_WINDOW_SIZE = 100   -- minimum width/height when resizing
local MIN_DELTA = 2           -- minimum pixel movement to trigger update

-- Cache frequently used functions
local absoluteTime = hs.timer.absoluteTime
local absolutePosition = hs.mouse.absolutePosition
local orderedWindows = hs.window.orderedWindows
local max = math.max
local abs = math.abs

-- Helper: find topmost window under cursor
local function windowUnderCursor(mousePos)
  local wins = orderedWindows()
  for _, w in ipairs(wins) do
    if w:isVisible() and w:isStandard() then
      local f = w:frame()
      if mousePos.x >= f.x and mousePos.x <= f.x + f.w and
         mousePos.y >= f.y and mousePos.y <= f.y + f.h then
        return w
      end
    end
  end
  return nil
end

-- Combined eventtap for both flags and mouse movement
local holdMoveWatcher = hs.eventtap.new(
  { hs.eventtap.event.types.flagsChanged, hs.eventtap.event.types.mouseMoved },
  function(e)
    local eventType = e:getType()
    local flags = e:getFlags()

    -- Detect modifier combinations
    local cmdOpt = flags.cmd and flags.alt and not flags.shift and not flags.ctrl
    local cmdOptShift = flags.cmd and flags.alt and flags.shift and not flags.ctrl

    if eventType == hs.eventtap.event.types.flagsChanged then
      -- Determine target mode based on modifiers
      local targetMode = nil
      if cmdOptShift then
        targetMode = "resize"
      elseif cmdOpt then
        targetMode = "move"
      end

      if targetMode and not holdState.mode then
        -- Activating: entering move or resize mode
        local mousePos = absolutePosition()
        local win = windowUnderCursor(mousePos)

        if win then
          local f = win:frame()
          holdState.mode = targetMode
          holdState.window = win
          holdState.initialMousePos = { x = mousePos.x, y = mousePos.y }
          holdState.initialFrame = { x = f.x, y = f.y, w = f.w, h = f.h }
          holdState.lastUpdate = 0
        end

      elseif targetMode and holdState.mode and targetMode ~= holdState.mode then
        -- Switching modes (e.g., added or released shift)
        local mousePos = absolutePosition()
        local f = holdState.window:frame()
        holdState.mode = targetMode
        holdState.initialMousePos = { x = mousePos.x, y = mousePos.y }
        holdState.initialFrame = { x = f.x, y = f.y, w = f.w, h = f.h }

      elseif not targetMode and holdState.mode then
        -- Deactivating: modifiers released
        holdState.mode = nil
        holdState.window = nil
        holdState.initialMousePos = nil
        holdState.initialFrame = nil
      end

    elseif eventType == hs.eventtap.event.types.mouseMoved then
      if holdState.mode and holdState.window then
        -- Throttle updates for smoother movement (nanosecond precision)
        local now = absoluteTime()
        if now - holdState.lastUpdate < THROTTLE_NS then
          return false
        end
        holdState.lastUpdate = now

        -- Quick validity check before pcall overhead
        if not holdState.window:isVisible() then
          holdState.mode = nil
          holdState.window = nil
          return false
        end

        local currentMouse = absolutePosition()
        local deltaX = currentMouse.x - holdState.initialMousePos.x
        local deltaY = currentMouse.y - holdState.initialMousePos.y

        -- Skip tiny movements (reduces jitter from hand tremor)
        if abs(deltaX) < MIN_DELTA and abs(deltaY) < MIN_DELTA then
          return false
        end

        local init = holdState.initialFrame
        local ok, _ = pcall(function()
          if holdState.mode == "move" then
            -- Move: use setTopLeft (more efficient than setFrame for position-only)
            holdState.window:setTopLeft({
              x = init.x + deltaX,
              y = init.y + deltaY
            })

          elseif holdState.mode == "resize" then
            -- Resize: keep position, adjust size (with minimum)
            local newW = max(MIN_WINDOW_SIZE, init.w + deltaX)
            local newH = max(MIN_WINDOW_SIZE, init.h + deltaY)
            holdState.window:setFrame({
              x = init.x,
              y = init.y,
              w = newW,
              h = newH
            }, 0)
          end
        end)
        if not ok then
          -- Reset state on error
          holdState.mode = nil
          holdState.window = nil
        end
      end
    end

    return false
  end
)

-- Keep reference to prevent garbage collection
M.holdMoveWatcher = holdMoveWatcher
holdMoveWatcher:start()

----------------------------------------------------
-- Toggle Floating with Margins (Hyper + D)
-- Pops out of Aerospace tiling and positions with gaps matching tiled mode
----------------------------------------------------
local OUTER_GAP = 12
local TOP_GAP = 44  -- matches aerospace outer.top

M.toggleFloatWithMargins = function()
  -- Toggle Aerospace fullscreen (pops in/out of tiling)
  hs.execute("/opt/homebrew/bin/aerospace fullscreen", true)

  -- Brief delay for Aerospace to process
  hs.timer.doAfter(0.05, function()
    local win = hs.window.focusedWindow()
    if not win then return end

    -- Check if now floating (fullscreen in Aerospace terms)
    local output = hs.execute("/opt/homebrew/bin/aerospace list-windows --focused --format '%{window-id}|%{floating}'", true)
    local isFloating = output and output:match("|true")

    if isFloating then
      -- Position with margins matching tiled gaps
      local screen = win:screen()
      local screenFrame = screen:frame()

      win:setFrame({
        x = screenFrame.x + OUTER_GAP,
        y = screenFrame.y + TOP_GAP,
        w = screenFrame.w - (OUTER_GAP * 2),
        h = screenFrame.h - TOP_GAP - OUTER_GAP
      }, 0)
    end
  end)
end

return M