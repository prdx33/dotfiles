------------------------------------------------------------
-- HoldToAction: Shared base module for hold-to-quit/close HUDs
-- Single eventtap, shared watchdog, shared caffeinate watcher
--
-- Usage:
--   local HoldToAction = require("holdToAction")
--   local quit  = HoldToAction.new(quitConfig)
--   local close = HoldToAction.new(closeConfig)
--   local dispatcher = HoldToAction.createDispatcher({
--     [hs.keycodes.map.q] = quit,
--     [hs.keycodes.map.w] = close,
--   })
--   dispatcher:start()
------------------------------------------------------------

local HoldToAction = {}

------------------------------------------------------------
-- CONSTANTS
------------------------------------------------------------

HoldToAction.States = {
  IDLE = "idle",
  HOLDING = "holding",
  TRIGGERED = "triggered",
  FADING = "fading",
  AWAITING_RELEASE = "awaiting_release",
}

-- Terminal style (matches Hammerspoon alert style)
HoldToAction.style = {
  bg    = { white = 0.1, alpha = 0.85 },
  text  = { white = 0.9, alpha = 1 },
  bar   = { white = 0.4, alpha = 0.5 },
  fill  = { white = 0.9, alpha = 1 },
  amber = { red = 1, green = 0.75, blue = 0.3, alpha = 1 },
  mint  = { red = 0.6, green = 1, blue = 0.8, alpha = 1 },
}

------------------------------------------------------------
-- HELPERS (module-level)
------------------------------------------------------------

local function now()
  return hs.timer.absoluteTime() / 1e9
end

local function activeScreenFrame()
  local win = hs.window.frontmostWindow()
  local scr = (win and win:screen()) or hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
  return scr:fullFrame()
end

local function truncateTitle(title, maxLen)
  if not title then return "Window" end
  if not maxLen then return title end
  if #title <= maxLen then return title end
  return string.sub(title, 1, maxLen - 1) .. "\xe2\x80\xa6"
end

------------------------------------------------------------
-- INSTANCE CONSTRUCTOR
------------------------------------------------------------

function HoldToAction.new(config)
  local instance = {
    config = config,
    passthroughCount = 0,
    state = {
      current = HoldToAction.States.IDLE,
      canvas = nil,
      progressTimer = nil,
      fadeTimer = nil,
      startTime = nil,
      fadeStartTime = nil,
      displayLabel = nil,
      iconPath = nil,
      targetWindowId = nil,
      lastEventTime = 0,
      lastTriggerTime = 0,
    },
    computed = {
      barWidth = 0,
      fillColor = { red = 0.9, green = 0.9, blue = 0.9, alpha = 1 },
    },
  }
  return setmetatable(instance, { __index = HoldToAction })
end

------------------------------------------------------------
-- LOGGING
------------------------------------------------------------

function HoldToAction:log(msg)
  print("[" .. self.config.name .. "] " .. msg)
end

------------------------------------------------------------
-- TIMER MANAGEMENT
------------------------------------------------------------

function HoldToAction:stopProgressTimer()
  if self.state.progressTimer then
    self.state.progressTimer:stop()
    self.state.progressTimer = nil
  end
end

function HoldToAction:stopFadeTimer()
  if self.state.fadeTimer then
    self.state.fadeTimer:stop()
    self.state.fadeTimer = nil
  end
end

function HoldToAction:stopAllTimers()
  self:stopProgressTimer()
  self:stopFadeTimer()
end

------------------------------------------------------------
-- CANVAS MANAGEMENT
------------------------------------------------------------

function HoldToAction:destroyCanvas()
  if self.state.canvas then
    pcall(function() self.state.canvas:delete() end)
    self.state.canvas = nil
  end
end

function HoldToAction:createCanvas()
  self:destroyCanvas()

  local cfg = self.config
  local sf = activeScreenFrame()
  local x = sf.x + (sf.w - cfg.hudWidth) / 2
  local y = sf.y + (sf.h - cfg.hudHeight) / 2

  local label = truncateTitle(self.state.displayLabel, cfg.maxTitleLength)

  local canvas = hs.canvas.new({ x = x, y = y, w = cfg.hudWidth, h = cfg.hudHeight })
  if not canvas then
    self:log("ERROR: Failed to create canvas")
    return false
  end

  canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
  canvas:level(hs.canvas.windowLevels.cursor)

  local barWidth = cfg.hudWidth - (cfg.barPadding * 2)
  local barY = cfg.hudHeight - cfg.barPadding - cfg.barHeight
  local idx = 1

  -- Background
  canvas[idx] = {
    type = "rectangle", action = "fill",
    roundedRectRadii = { xRadius = 6, yRadius = 6 },
    fillColor = self.style.bg
  }
  idx = idx + 1

  -- Optional title (bold, top-centered)
  if cfg.hudTitle then
    canvas[idx] = {
      type = "text",
      text = cfg.hudTitle,
      textFont = "JetBrains Mono Bold",
      textSize = 14,
      textColor = { white = 1, alpha = 1 },
      frame = { x = 0, y = math.floor(cfg.hudHeight * 0.22), w = cfg.hudWidth, h = 20 },
      textAlignment = "center"
    }
    idx = idx + 1
  end

  -- Content row: optional icon + label (centered as a unit when hudTitle is set)
  local contentY = cfg.hudTitle and math.floor(cfg.hudHeight * 0.42) or 12
  local labelText = cfg.hudTitle and label or (cfg.hudPrefix .. label)

  if cfg.hudTitle then
    -- Estimate content width to center icon+label as a unit
    local iconSize = self.state.iconPath and 22 or 0
    local iconGap = self.state.iconPath and 8 or 0
    local charWidth = 8.4  -- approx for JetBrains Mono 14pt
    local textWidth = #labelText * charWidth
    local totalWidth = iconSize + iconGap + textWidth
    local startX = (cfg.hudWidth - totalWidth) / 2

    if self.state.iconPath then
      local iconImg = hs.image.imageFromPath(self.state.iconPath)
      if iconImg then
        canvas[idx] = {
          type = "image",
          image = iconImg,
          frame = { x = startX, y = contentY, w = iconSize, h = iconSize },
          imageScaling = "scaleToFit"
        }
        idx = idx + 1
      end
    end

    canvas[idx] = {
      type = "text",
      text = labelText,
      textFont = "JetBrains Mono",
      textSize = 14,
      textColor = self.style.text,
      frame = { x = startX + iconSize + iconGap, y = contentY, w = barWidth, h = 24 },
      textAlignment = "left"
    }
    idx = idx + 1
  else
    -- Simple layout (no title): prefix + label, left-aligned
    canvas[idx] = {
      type = "text",
      text = labelText,
      textFont = "JetBrains Mono",
      textSize = 14,
      textColor = self.style.text,
      frame = { x = cfg.barPadding, y = contentY, w = barWidth, h = 24 },
      textAlignment = "left"
    }
    idx = idx + 1
  end

  -- Progress bar background
  canvas[idx] = {
    type = "rectangle", action = "fill",
    frame = { x = cfg.barPadding, y = barY, w = barWidth, h = cfg.barHeight },
    roundedRectRadii = { xRadius = 2, yRadius = 2 },
    fillColor = self.style.bar
  }
  idx = idx + 1

  -- Progress bar fill (starts at 0 width)
  canvas[idx] = {
    type = "rectangle", action = "fill",
    frame = { x = cfg.barPadding, y = barY, w = 0, h = cfg.barHeight },
    roundedRectRadii = { xRadius = 2, yRadius = 2 },
    fillColor = self.style.fill
  }
  self.computed.fillIdx = idx

  canvas:show()
  self.state.canvas = canvas
  self.computed.barWidth = barWidth
  return true
end

------------------------------------------------------------
-- STATE TRANSITIONS
------------------------------------------------------------

function HoldToAction:transitionTo(newState)
  local oldState = self.state.current
  if oldState == newState then return end
  self:log("State: " .. (oldState or "nil") .. " -> " .. newState)
  self.state.current = newState
end

function HoldToAction:resetToIdle()
  self:stopAllTimers()
  self:destroyCanvas()
  self.state.startTime = nil
  self.state.fadeStartTime = nil
  self.state.displayLabel = nil
  self.state.iconPath = nil
  self.state.targetWindowId = nil
  self:transitionTo(self.States.IDLE)
end

------------------------------------------------------------
-- PROGRESS UPDATE (called at updateRate Hz while holding)
------------------------------------------------------------

function HoldToAction:updateProgress()
  if self.state.current ~= self.States.HOLDING then
    self:stopProgressTimer()
    return
  end

  if not self.state.canvas then
    self:log("WARN: Canvas missing during progress update")
    self:resetToIdle()
    return
  end

  local pct = (now() - self.state.startTime) / self.config.holdThreshold
  if pct > 1 then pct = 1 end

  -- Update progress bar width
  local fi = self.computed.fillIdx
  self.state.canvas[fi].frame.w = self.computed.barWidth * pct

  -- Gradient from white to amber (reuse table to reduce GC)
  local c = self.computed.fillColor
  c.red   = 0.9 + 0.1 * pct     -- 0.9 -> 1.0
  c.green = 0.9 - 0.15 * pct    -- 0.9 -> 0.75
  c.blue  = 0.9 - 0.6 * pct     -- 0.9 -> 0.3
  self.state.canvas[fi].fillColor = c

  if pct >= 1 then
    self:triggerAction()
  end
end

------------------------------------------------------------
-- TRIGGER ACTION
------------------------------------------------------------

function HoldToAction:triggerAction()
  self:stopProgressTimer()
  self:transitionTo(self.States.TRIGGERED)
  self.state.lastTriggerTime = now()

  -- Flash mint green
  if self.state.canvas then
    self.state.canvas[self.computed.fillIdx].fillColor = self.style.mint
  end

  -- Delegate to config callback
  self.config.onTrigger(self)

  -- Schedule fade after delay
  hs.timer.doAfter(self.config.fadeDelay, function()
    self:startFade()
  end)
end

------------------------------------------------------------
-- FADE ANIMATION
------------------------------------------------------------

function HoldToAction:startFade()
  if self.state.current ~= self.States.TRIGGERED then
    return
  end

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

function HoldToAction:updateFade()
  if self.state.current ~= self.States.FADING then
    self:stopFadeTimer()
    return
  end

  if not self.state.canvas then
    self:stopFadeTimer()
    self:transitionTo(self.States.AWAITING_RELEASE)
    return
  end

  local alpha = 1 - (now() - self.state.fadeStartTime) / self.config.fadeDuration

  if alpha < 0.01 then
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

function HoldToAction:handleKeyDown(isShiftHeld)
  self.state.lastEventTime = now()

  -- Cooldown check (prevents double-trigger from key repeat)
  if self.config.cooldown > 0 then
    if (now() - (self.state.lastTriggerTime or 0)) < self.config.cooldown then
      return true
    end
  end

  -- Shift shortcut = instant action, bypass hold
  if isShiftHeld then
    return self.config.onShiftAction(self)
  end

  local currentState = self.state.current

  -- IDLE -> start holding
  if currentState == self.States.IDLE then
    local ok = self.config.onCaptureTarget(self)
    if ok == false then return true end

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

  -- All other states: block the event
  return true
end

function HoldToAction:handleKeyUp()
  local currentState = self.state.current

  -- HOLDING -> cancel (released early)
  if currentState == self.States.HOLDING then
    local dur = now() - (self.state.startTime or now())
    self:log(string.format("Cancelled (released after %.0fms)", dur * 1000))
    self:resetToIdle()
    return true
  end

  -- AWAITING_RELEASE -> back to idle
  if currentState == self.States.AWAITING_RELEASE then
    self:log("Key released, ready for next action")
    self:resetToIdle()
    return true
  end

  -- TRIGGERED or FADING -> behaviour depends on config
  if currentState == self.States.TRIGGERED or currentState == self.States.FADING then
    if self.config.onKeyUpDuringFade == "reset_idle" then
      self:log("Key released during fade, ready for next action")
      self:resetToIdle()
    end
    -- "await_release" stays in state; fade completion handles transition
    return true
  end

  return false
end

function HoldToAction:handleEvent(e)
  local code = e:getKeyCode()
  if code ~= self.config.keycode then return false end

  -- Let synthesised keystrokes through (Close sets this to 2)
  if self.passthroughCount > 0 then
    self.passthroughCount = self.passthroughCount - 1
    self:log("Passing through generated event (" .. self.passthroughCount .. " remaining)")
    return false
  end

  local eventType = e:getType()
  local flags = e:getFlags()

  if eventType == hs.eventtap.event.types.keyDown then
    local hasCmd = flags.cmd and not flags.alt and not flags.ctrl
    if not hasCmd then return false end
    return self:handleKeyDown(flags.shift)
  end

  if eventType == hs.eventtap.event.types.keyUp then
    if self.state.current and self.state.current ~= self.States.IDLE then
      return self:handleKeyUp()
    end
  end

  return false
end

------------------------------------------------------------
-- DISPATCHER: Single eventtap + shared watchdog + caffeinate
------------------------------------------------------------

local Dispatcher = {}
Dispatcher.__index = Dispatcher

function HoldToAction.createDispatcher(keycodeMap)
  local d = setmetatable({
    keycodeMap = keycodeMap,
    tap = nil,
    watchdogTimer = nil,
    caffeineWatcher = nil,
    startCount = 0,
  }, Dispatcher)
  return d
end

function Dispatcher:start()
  self:startTap()
  self:startWatchdog()
  self:startCaffeineWatcher()
  print("[HoldToAction] Dispatcher started")
end

function Dispatcher:stop()
  if self.tap then
    pcall(function() self.tap:stop() end)
    self.tap = nil
  end
  if self.watchdogTimer then
    self.watchdogTimer:stop()
    self.watchdogTimer = nil
  end
  if self.caffeineWatcher then
    self.caffeineWatcher:stop()
    self.caffeineWatcher = nil
  end
  for _, inst in pairs(self.keycodeMap) do
    inst:resetToIdle()
  end
  print("[HoldToAction] Dispatcher stopped")
end

------------------------------------------------------------
-- EVENTTAP (single tap for all instances)
------------------------------------------------------------

function Dispatcher:createTap()
  local keycodeMap = self.keycodeMap
  return hs.eventtap.new(
    { hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp },
    function(e)
      local code = e:getKeyCode()
      local instance = keycodeMap[code]
      if not instance then return false end

      local ok, result = pcall(function()
        return instance:handleEvent(e)
      end)
      if not ok then
        print("[HoldToAction] ERROR in " .. instance.config.name .. ": " .. tostring(result))
        pcall(function() instance:resetToIdle() end)
        return false
      end
      return result or false
    end
  )
end

function Dispatcher:startTap()
  self.startCount = self.startCount + 1
  print("[HoldToAction] Starting eventtap (attempt #" .. self.startCount .. ")")

  if self.tap then
    pcall(function() self.tap:stop() end)
    self.tap = nil
  end

  -- Reset all instances on tap restart
  for _, inst in pairs(self.keycodeMap) do
    if inst.state.current ~= HoldToAction.States.IDLE then
      inst:log("Resetting state during tap restart")
      inst:resetToIdle()
    end
  end

  self.tap = self:createTap()
  if not self.tap then
    print("[HoldToAction] ERROR: Failed to create eventtap")
    return false
  end

  local started = self.tap:start()
  if started then
    print("[HoldToAction] Eventtap started successfully")
    return true
  else
    print("[HoldToAction] ERROR: Eventtap failed to start")
    return false
  end
end

function Dispatcher:restartTap()
  self:startTap()
end

------------------------------------------------------------
-- WATCHDOG (shared, monitors all instances)
------------------------------------------------------------

function Dispatcher:startWatchdog()
  if self.watchdogTimer then
    self.watchdogTimer:stop()
  end

  self.watchdogTimer = hs.timer.doEvery(30, function()
    -- Check tap health
    if not self.tap or not self.tap:isEnabled() then
      print("[HoldToAction] Watchdog: tap disabled, restarting...")
      self:restartTap()
      return
    end

    -- Check each instance for stuck states
    for _, inst in pairs(self.keycodeMap) do
      local st = inst.state.current
      if st == HoldToAction.States.HOLDING then
        local dur = now() - (inst.state.startTime or now())
        if dur > 5 then
          inst:log("Watchdog: stuck in HOLDING for " .. string.format("%.1f", dur) .. "s, resetting")
          inst:resetToIdle()
        end
      elseif st == HoldToAction.States.TRIGGERED or st == HoldToAction.States.FADING then
        if inst.state.fadeStartTime then
          local dur = now() - inst.state.fadeStartTime
          if dur > 3 then
            inst:log("Watchdog: stuck in fade, resetting")
            inst:resetToIdle()
          end
        end
      end
    end
  end)

  print("[HoldToAction] Watchdog started (30s interval)")
end

------------------------------------------------------------
-- CAFFEINATE WATCHER (shared, restarts tap on wake)
------------------------------------------------------------

function Dispatcher:startCaffeineWatcher()
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
      print("[HoldToAction] Caffeinate: " .. eventName)
      hs.timer.doAfter(1.0, function()
        self:restartTap()
      end)
    end
  end)

  self.caffeineWatcher:start()
  print("[HoldToAction] Caffeinate watcher started")
end

return HoldToAction
