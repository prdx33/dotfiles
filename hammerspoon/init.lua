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
package.loaded["windowManager"] = nil  -- force reload on config reload
local wm = require("windowManager")

------------------------------------------------------------
-- Cheatsheet (simple alert style)
------------------------------------------------------------
local hyper = {"cmd", "alt", "ctrl", "shift"}

local cheatsheetText = [[
HYPER (⌘⌃⌥⇧)
Q-P  Summon workspace    A  Toggle mode
S/F  Left/Right          D  Center/Pop-out
X/V  Focus L/R           C  Focus monitor
G    Move to monitor     B/N  Tiles H/V
H/J/K/L  Focus (vim)     ;  Service mode

ALT (⌥)
Q-P  Send to workspace   S/F  Resize ±50
D    Reset layout        G  Move workspace

ALT+SHIFT: Send + follow, Resize ±150
]]

hs.hotkey.bind(hyper, "slash", function()
  hs.alert.show(cheatsheetText, 4)
end)

------------------------------------------------------------
-- Toggle Menu Bar (Hyper + ')

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
-- Robust state machine implementation
------------------------------------------------------------

local HoldToQuit = {}

-- Configuration
HoldToQuit.config = {
  holdThreshold = 0.5,    -- seconds to hold before quit
  hudWidth = 220,
  hudHeight = 60,
  barHeight = 4,
  barPadding = 16,
  fadeDelay = 0.5,        -- pause before fadeout after quit
  fadeDuration = 0.15,
  updateRate = 60,        -- Hz
  watchdogInterval = 30,  -- seconds between health checks
}

-- State machine states
HoldToQuit.States = {
  IDLE = "idle",              -- waiting for Cmd+Q
  HOLDING = "holding",        -- key held, progress bar filling
  TRIGGERED = "triggered",    -- threshold reached, app being killed
  FADING = "fading",          -- HUD fading out
  AWAITING_RELEASE = "awaiting_release",  -- waiting for key release after quit
}

-- Terminal style (matches alert style)
HoldToQuit.style = {
  bg    = { white = 0.1, alpha = 0.85 },
  text  = { white = 0.9, alpha = 1 },
  bar   = { white = 0.4, alpha = 0.5 },
  fill  = { white = 0.9, alpha = 1 },
  amber = { red = 1, green = 0.75, blue = 0.3, alpha = 1 },
  mint  = { red = 0.6, green = 1, blue = 0.8, alpha = 1 },
}

-- Instance state (single source of truth)
HoldToQuit.state = {
  current = nil,        -- current state from States enum
  canvas = nil,         -- the HUD canvas
  progressTimer = nil,  -- timer for progress updates
  fadeTimer = nil,      -- timer for fade animation
  startTime = nil,      -- when holding started (absolute time)
  fadeStartTime = nil,  -- when fade started
  appName = nil,        -- name of app being quit
  lastEventTime = 0,    -- last time we received any Cmd+Q event
}

-- Eventtap and watchers
HoldToQuit.tap = nil
HoldToQuit.caffeineWatcher = nil
HoldToQuit.watchdogTimer = nil
HoldToQuit.startCount = 0

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------

local function log(msg)
  print("[HoldToQuit] " .. msg)
end

local function now()
  return hs.timer.absoluteTime() / 1e9
end

local function activeScreenFrame()
  local win = hs.window.frontmostWindow()
  local scr = (win and win:screen()) or hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
  return scr:fullFrame()
end

------------------------------------------------------------
-- TIMER MANAGEMENT (defensive - always stop before start)
------------------------------------------------------------

function HoldToQuit:stopProgressTimer()
  if self.state.progressTimer then
    self.state.progressTimer:stop()
    self.state.progressTimer = nil
  end
end

function HoldToQuit:stopFadeTimer()
  if self.state.fadeTimer then
    self.state.fadeTimer:stop()
    self.state.fadeTimer = nil
  end
end

function HoldToQuit:stopAllTimers()
  self:stopProgressTimer()
  self:stopFadeTimer()
end

------------------------------------------------------------
-- CANVAS MANAGEMENT
------------------------------------------------------------

function HoldToQuit:destroyCanvas()
  if self.state.canvas then
    -- Use pcall in case canvas is already invalid
    pcall(function() self.state.canvas:delete() end)
    self.state.canvas = nil
  end
end

function HoldToQuit:createCanvas()
  self:destroyCanvas()

  local cfg = self.config
  local sf = activeScreenFrame()
  local x = sf.x + (sf.w - cfg.hudWidth) / 2
  local y = sf.y + (sf.h - cfg.hudHeight) / 2

  local app = hs.application.frontmostApplication()
  self.state.appName = (app and app:name()) or "App"

  local canvas = hs.canvas.new({ x = x, y = y, w = cfg.hudWidth, h = cfg.hudHeight })
  if not canvas then
    log("ERROR: Failed to create canvas")
    return false
  end

  canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
  canvas:level(hs.canvas.windowLevels.cursor)

  local barWidth = cfg.hudWidth - (cfg.barPadding * 2)
  local barY = cfg.hudHeight - cfg.barPadding - cfg.barHeight

  -- Background
  canvas[1] = {
    type = "rectangle", action = "fill",
    roundedRectRadii = { xRadius = 6, yRadius = 6 },
    fillColor = self.style.bg
  }

  -- App name
  canvas[2] = {
    type = "text",
    text = "Quitting " .. self.state.appName,
    textFont = "JetBrains Mono",
    textSize = 14,
    textColor = self.style.text,
    frame = { x = cfg.barPadding, y = 12, w = barWidth, h = 24 },
    textAlignment = "left"
  }

  -- Progress bar background
  canvas[3] = {
    type = "rectangle", action = "fill",
    frame = { x = cfg.barPadding, y = barY, w = barWidth, h = cfg.barHeight },
    roundedRectRadii = { xRadius = 2, yRadius = 2 },
    fillColor = self.style.bar
  }

  -- Progress bar fill (starts at 0 width)
  canvas[4] = {
    type = "rectangle", action = "fill",
    frame = { x = cfg.barPadding, y = barY, w = 0, h = cfg.barHeight },
    roundedRectRadii = { xRadius = 2, yRadius = 2 },
    fillColor = self.style.fill
  }

  canvas:show()
  self.state.canvas = canvas
  return true
end

------------------------------------------------------------
-- STATE TRANSITIONS (explicit and logged)
------------------------------------------------------------

function HoldToQuit:transitionTo(newState)
  local oldState = self.state.current
  if oldState == newState then return end

  log("State: " .. (oldState or "nil") .. " -> " .. newState)
  self.state.current = newState
end

function HoldToQuit:resetToIdle()
  self:stopAllTimers()
  self:destroyCanvas()
  self.state.startTime = nil
  self.state.fadeStartTime = nil
  self.state.appName = nil
  self:transitionTo(self.States.IDLE)
end

------------------------------------------------------------
-- PROGRESS UPDATE (called at 60Hz while holding)
------------------------------------------------------------

function HoldToQuit:updateProgress()
  -- Guard: only update in HOLDING state
  if self.state.current ~= self.States.HOLDING then
    self:stopProgressTimer()
    return
  end

  -- Guard: canvas must exist
  if not self.state.canvas then
    log("WARN: Canvas missing during progress update")
    self:resetToIdle()
    return
  end

  local elapsed = now() - self.state.startTime
  local pct = math.min(elapsed / self.config.holdThreshold, 1)
  local cfg = self.config
  local barWidth = cfg.hudWidth - (cfg.barPadding * 2)

  -- Update progress bar width
  self.state.canvas[4].frame.w = barWidth * pct

  -- Gradient from white to amber
  local style = self.style
  local r = style.fill.white + (style.amber.red - style.fill.white) * pct
  local g = style.fill.white + (style.amber.green - style.fill.white) * pct
  local b = style.fill.white + (style.amber.blue - style.fill.white) * pct
  self.state.canvas[4].fillColor = { red = r, green = g, blue = b, alpha = 1 }

  -- Check if threshold reached
  if pct >= 1 then
    self:triggerQuit()
  end
end

------------------------------------------------------------
-- TRIGGER QUIT
------------------------------------------------------------

function HoldToQuit:triggerQuit()
  self:stopProgressTimer()
  self:transitionTo(self.States.TRIGGERED)

  -- Flash mint green
  if self.state.canvas then
    self.state.canvas[4].fillColor = self.style.mint
  end

  -- Kill the app
  local app = hs.application.frontmostApplication()
  if app then
    log("Killing app: " .. (app:name() or "unknown"))
    app:kill()
  end

  -- Schedule fade after delay
  hs.timer.doAfter(self.config.fadeDelay, function()
    self:startFade()
  end)
end

------------------------------------------------------------
-- FADE ANIMATION
------------------------------------------------------------

function HoldToQuit:startFade()
  -- Guard: must be in TRIGGERED state
  if self.state.current ~= self.States.TRIGGERED then
    return
  end

  -- Guard: canvas must exist
  if not self.state.canvas then
    self:transitionTo(self.States.AWAITING_RELEASE)
    return
  end

  self:transitionTo(self.States.FADING)
  self.state.fadeStartTime = now()

  self:stopFadeTimer()
  self.state.fadeTimer = hs.timer.doEvery(1 / self.config.updateRate, function()
    self:updateFade()
  end)
end

function HoldToQuit:updateFade()
  -- Guard: only update in FADING state
  if self.state.current ~= self.States.FADING then
    self:stopFadeTimer()
    return
  end

  -- Guard: canvas must exist
  if not self.state.canvas then
    self:stopFadeTimer()
    self:transitionTo(self.States.AWAITING_RELEASE)
    return
  end

  local elapsed = now() - self.state.fadeStartTime
  local alpha = 1 - (elapsed / self.config.fadeDuration)

  if alpha <= 0 then
    self:stopFadeTimer()
    self:destroyCanvas()
    self:transitionTo(self.States.AWAITING_RELEASE)
  else
    pcall(function() self.state.canvas:alpha(alpha) end)
  end
end

------------------------------------------------------------
-- EVENT HANDLING
------------------------------------------------------------

function HoldToQuit:handleKeyDown()
  self.state.lastEventTime = now()

  local currentState = self.state.current

  -- IDLE -> start holding
  if currentState == self.States.IDLE then
    self:transitionTo(self.States.HOLDING)
    self.state.startTime = now()
    if not self:createCanvas() then
      self:resetToIdle()
      return true
    end
    self:stopProgressTimer()
    self.state.progressTimer = hs.timer.doEvery(1 / self.config.updateRate, function()
      self:updateProgress()
    end)
    return true
  end

  -- HOLDING -> continue (keyDown repeats are normal)
  if currentState == self.States.HOLDING then
    return true
  end

  -- TRIGGERED, FADING, AWAITING_RELEASE -> block but don't start new quit
  return true
end

function HoldToQuit:handleKeyUp()
  local currentState = self.state.current

  -- HOLDING -> cancel (user released early)
  if currentState == self.States.HOLDING then
    local holdDuration = now() - (self.state.startTime or now())
    log(string.format("Cancelled (released after %.0fms)", holdDuration * 1000))
    self:resetToIdle()
    return true
  end

  -- AWAITING_RELEASE -> now we can go back to idle
  if currentState == self.States.AWAITING_RELEASE then
    log("Key released, ready for next quit")
    self:resetToIdle()
    return true
  end

  -- TRIGGERED or FADING -> note that key was released
  if currentState == self.States.TRIGGERED or currentState == self.States.FADING then
    -- Key released during quit/fade - we'll go to IDLE after fade completes
    -- The fade completion will handle transition
    return true
  end

  return false
end

function HoldToQuit:handleEvent(e)
  local code = e:getKeyCode()
  local flags = e:getFlags()

  -- Only care about Q key
  local isQ = code == hs.keycodes.map.q
  if not isQ then return false end

  local eventType = e:getType()
  local isKeyDown = eventType == hs.eventtap.event.types.keyDown
  local isKeyUp = eventType == hs.eventtap.event.types.keyUp

  -- For keyDown, require pure Cmd (no shift/alt/ctrl)
  if isKeyDown then
    local pureCmd = flags.cmd and not flags.shift and not flags.alt and not flags.ctrl
    if not pureCmd then return false end
    return self:handleKeyDown()
  end

  -- For keyUp, handle if we're in a relevant state
  if isKeyUp then
    local currentState = self.state.current
    if currentState and currentState ~= self.States.IDLE then
      return self:handleKeyUp()
    end
  end

  return false
end

------------------------------------------------------------
-- EVENTTAP MANAGEMENT
------------------------------------------------------------

function HoldToQuit:createTap()
  return hs.eventtap.new(
    { hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp },
    function(e)
      -- Wrap in pcall to prevent tap from being disabled on error
      local ok, result = pcall(function()
        return self:handleEvent(e)
      end)
      if not ok then
        log("ERROR in event handler: " .. tostring(result))
        -- On error, reset to safe state but don't crash
        pcall(function() self:resetToIdle() end)
        return false
      end
      return result or false
    end
  )
end

function HoldToQuit:startTap()
  self.startCount = self.startCount + 1
  log("Starting eventtap (attempt #" .. self.startCount .. ")")

  -- Stop existing tap
  if self.tap then
    pcall(function() self.tap:stop() end)
    self.tap = nil
  end

  -- Reset state when restarting tap (prevents stuck states)
  if self.state.current ~= self.States.IDLE then
    log("Resetting state during tap restart")
    self:resetToIdle()
  end

  -- Create and start new tap
  self.tap = self:createTap()
  if not self.tap then
    log("ERROR: Failed to create eventtap")
    return false
  end

  local started = self.tap:start()
  if started then
    log("Eventtap started successfully")
    return true
  else
    log("ERROR: Eventtap failed to start")
    return false
  end
end

------------------------------------------------------------
-- WATCHDOG (health monitoring)
------------------------------------------------------------

function HoldToQuit:startWatchdog()
  if self.watchdogTimer then
    self.watchdogTimer:stop()
  end

  self.watchdogTimer = hs.timer.doEvery(self.config.watchdogInterval, function()
    -- Check if tap is enabled
    local tapEnabled = self.tap and self.tap:isEnabled()
    if not tapEnabled then
      log("Watchdog: tap disabled, restarting...")
      self:startTap()
      return
    end

    -- Check for stuck states (holding for too long without resolution)
    if self.state.current == self.States.HOLDING then
      local holdDuration = now() - (self.state.startTime or now())
      if holdDuration > 5 then  -- 5 seconds is way too long
        log("Watchdog: stuck in HOLDING state for " .. string.format("%.1f", holdDuration) .. "s, resetting")
        self:resetToIdle()
      end
    end

    -- Check for stuck in TRIGGERED/FADING (should complete quickly)
    if self.state.current == self.States.TRIGGERED or self.state.current == self.States.FADING then
      if self.state.fadeStartTime then
        local fadeDuration = now() - self.state.fadeStartTime
        if fadeDuration > 3 then  -- 3 seconds is too long for fade
          log("Watchdog: stuck in fade, resetting")
          self:resetToIdle()
        end
      end
    end
  end)

  log("Watchdog started (interval: " .. self.config.watchdogInterval .. "s)")
end

------------------------------------------------------------
-- CAFFEINATE WATCHER (sleep/wake handling)
------------------------------------------------------------

function HoldToQuit:startCaffeineWatcher()
  if self.caffeineWatcher then
    self.caffeineWatcher:stop()
  end

  self.caffeineWatcher = hs.caffeinate.watcher.new(function(event)
    local eventNames = {
      [hs.caffeinate.watcher.systemDidWake] = "systemDidWake",
      [hs.caffeinate.watcher.screensDidUnlock] = "screensDidUnlock",
      [hs.caffeinate.watcher.screensDidWake] = "screensDidWake",
      [hs.caffeinate.watcher.sessionDidBecomeActive] = "sessionDidBecomeActive",
    }

    local eventName = eventNames[event]
    if eventName then
      log("Caffeinate: " .. eventName)
      -- Delay restart slightly to let system stabilise
      hs.timer.doAfter(1.0, function()
        self:startTap()
      end)
    end
  end)

  self.caffeineWatcher:start()
  log("Caffeinate watcher started")
end

------------------------------------------------------------
-- INITIALISATION
------------------------------------------------------------

function HoldToQuit:init()
  log("Initialising...")
  self.state.current = self.States.IDLE
  self:startTap()
  self:startWatchdog()
  self:startCaffeineWatcher()
  log("Ready")
end

-- Start!
HoldToQuit:init()
