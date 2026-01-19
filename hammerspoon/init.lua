------------------------------------------------------------
-- Alert Style
------------------------------------------------------------
hs.alert.defaultStyle.strokeColor = { white = 0, alpha = 0 }
hs.alert.defaultStyle.fillColor = { white = 0.1, alpha = 0.75 }
hs.alert.defaultStyle.textColor = { white = 0.9, alpha = 1 }
hs.alert.defaultStyle.textFont = "JetBrains Mono"
hs.alert.defaultStyle.textSize = 14
hs.alert.defaultStyle.radius = 6
hs.alert.defaultStyle.fadeInDuration = 0.05
hs.alert.defaultStyle.fadeOutDuration = 0.1
hs.alert.defaultStyle.duration = 0.15

------------------------------------------------------------
-- Minimise / Restore
------------------------------------------------------------
local wm = require("windowManager")

------------------------------------------------------------
-- Toggle Menu Bar (Hyper + ')
------------------------------------------------------------
local hyper = {"cmd", "alt", "ctrl", "shift"}

hs.hotkey.bind(hyper, "'", function()
  hs.applescript([[
    tell application "System Events"
      tell dock preferences
        set autohide menu bar to not autohide menu bar
      end tell
    end tell
  ]])
  hs.alert.show("Toggled Menu Bar", nil, nil, 0.3)
end)

-- ⌘M → minimise toggle
hs.hotkey.bind({"cmd"}, "m", wm.toggleMinimize)

------------------------------------------------------------
-- ⌘Q Hold-to-Quit HUD (Terminal Style)
------------------------------------------------------------

-- Timing
local holdThreshold = 0.5

-- HUD sizing
local hudWidth = 220
local hudHeight = 60
local barHeight = 4
local barPadding = 16

-- State
local indicator, progTimer = nil, nil
local holding, quitTriggered = false, false
local elapsed, lastTime = 0, nil
local appName = "App"
local currentKey = nil

-- Terminal style (matches alert style)
local termStyle = {
  bg    = { white = 0.1, alpha = 0.85 },
  text  = { white = 0.9, alpha = 1 },
  bar   = { white = 0.4, alpha = 0.5 },
  fill  = { white = 0.9, alpha = 1 },
  amber = { red = 1, green = 0.75, blue = 0.3, alpha = 1 },
}

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------
local function safeDelete()
  hs.timer.doAfter(0.01, function()
    if indicator then indicator:delete() end
    indicator = nil
  end)
end

local function cleanup(keepWaiting)
  if progTimer then progTimer:stop(); progTimer = nil end
  holding = false
  if not keepWaiting then quitTriggered = false end
  lastTime, elapsed = nil, 0
  currentKey = nil
  safeDelete()
end

local function activeScreenFrame()
  local win = hs.window.frontmostWindow()
  local scr = (win and win:screen()) or hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
  return scr:fullFrame()
end

------------------------------------------------------------
-- BUILD HUD
------------------------------------------------------------
local function buildHUD()
  local sf = activeScreenFrame()
  local x = sf.x + (sf.w - hudWidth) / 2
  local y = sf.y + (sf.h - hudHeight) / 2
  appName = (hs.application.frontmostApplication() and hs.application.frontmostApplication():name()) or "App"

  indicator = hs.canvas.new({ x = x, y = y, w = hudWidth, h = hudHeight }):show()
  indicator:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
  indicator:level(hs.canvas.windowLevels.cursor)

  local barWidth = hudWidth - (barPadding * 2)
  local barY = hudHeight - barPadding - barHeight

  -- Background
  indicator[1] = {
    type = "rectangle", action = "fill",
    roundedRectRadii = { xRadius = 6, yRadius = 6 },
    fillColor = termStyle.bg
  }

  -- App name
  indicator[2] = {
    type = "text",
    text = "Quitting " .. appName,
    textFont = "JetBrains Mono",
    textSize = 14,
    textColor = termStyle.text,
    frame = { x = barPadding, y = 12, w = barWidth, h = 24 },
    textAlignment = "left"
  }

  -- Progress bar background
  indicator[3] = {
    type = "rectangle", action = "fill",
    frame = { x = barPadding, y = barY, w = barWidth, h = barHeight },
    roundedRectRadii = { xRadius = 2, yRadius = 2 },
    fillColor = termStyle.bar
  }

  -- Progress bar fill (starts at 0 width)
  indicator[4] = {
    type = "rectangle", action = "fill",
    frame = { x = barPadding, y = barY, w = 0, h = barHeight },
    roundedRectRadii = { xRadius = 2, yRadius = 2 },
    fillColor = termStyle.fill
  }
end

------------------------------------------------------------
-- UPDATE LOOP (60 Hz)
------------------------------------------------------------
local function update()
  if not indicator then return end
  local now = hs.timer.absoluteTime() / 1e9
  if not lastTime then lastTime = now end
  local delta = now - lastTime
  lastTime = now
  elapsed = elapsed + delta

  local pct = math.min(elapsed / holdThreshold, 1)
  local barWidth = hudWidth - (barPadding * 2)

  -- Linear fill (no easing)
  indicator[4].frame.w = barWidth * pct

  if pct >= 1 and not quitTriggered then
    quitTriggered = true
    -- Turn bar amber
    indicator[4].fillColor = termStyle.amber
    -- Stop the update timer
    if progTimer then progTimer:stop(); progTimer = nil end
    -- Quit the app directly (avoids keystroke loop issues)
    local app = hs.application.frontmostApplication()
    if app then app:kill() end
    -- Keep HUD visible, then fade out
    hs.timer.doAfter(0.5, function()
      if not indicator then return end
      -- Fast fadeout over 0.15s
      local fadeStart = hs.timer.absoluteTime() / 1e9
      local fadeDuration = 0.15
      local fadeTimer
      fadeTimer = hs.timer.doEvery(1/60, function()
        if not indicator then
          if fadeTimer then fadeTimer:stop() end
          return
        end
        local elapsed = (hs.timer.absoluteTime() / 1e9) - fadeStart
        local alpha = 1 - (elapsed / fadeDuration)
        if alpha <= 0 then
          fadeTimer:stop()
          cleanup(true)
        else
          indicator:alpha(alpha)
        end
      end)
    end)
  end
end

------------------------------------------------------------
-- EVENT WATCHER
------------------------------------------------------------
local tap = hs.eventtap.new(
  { hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp },
  function(e)
    local code, flags = e:getKeyCode(), e:getFlags()
    local pureCmd = flags.cmd and not flags.shift and not flags.alt and not flags.ctrl

    local keyName = nil
    if code == hs.keycodes.map.q and pureCmd then keyName = "q" end

    if not keyName then return false end

    if e:getType() == hs.eventtap.event.types.keyDown then
      -- Block if already triggered (waiting for release)
      if quitTriggered then
        return true
      end

      if not holding then
        holding = true
        currentKey = keyName
        buildHUD()
        elapsed, lastTime = 0, nil
        progTimer = hs.timer.doEvery(1 / 60, update)
      end
      return true
    else
      -- keyUp: reset everything
      if holding and not quitTriggered then cleanup() end
      quitTriggered = false
      holding = false
      return true
    end
  end
)
tap:start()
