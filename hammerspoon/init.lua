------------------------------------------------------------
-- Minimise / Restore
------------------------------------------------------------
local wm = require("windowManager")

------------------------------------------------------------
-- ZMK Layer Indicator
------------------------------------------------------------
local layerIndicator = require("layerIndicator")
layerIndicator.start()

-- ⌘M → minimise toggle
hs.hotkey.bind({"cmd"}, "m", wm.toggleMinimize)

------------------------------------------------------------
-- Show / Hide Menu Bar
------------------------------------------------------------
-- Toggle macOS menu bar visibility
hs.hotkey.bind(
    {"ctrl", "alt"},
    "M",
    function()
        local current = hs.execute("defaults read NSGlobalDomain _HIHideMenuBar"):gsub("\n", "")
        if current == "1" then
            hs.execute("defaults write NSGlobalDomain _HIHideMenuBar -bool false")
        else
            hs.execute("defaults write NSGlobalDomain _HIHideMenuBar -bool true")
        end
        hs.execute("killall SystemUIServer")
        hs.alert.show("Toggled Menu Bar")
    end
)

------------------------------------------------------------
-- Tap Tab Hold Hyper
------------------------------------------------------------

-- ~/.hammerspoon/init.lua
local hyper = {"cmd", "alt", "ctrl", "shift"}

-- Map Caps Lock (via Karabiner) → F18
-- Then in Hammerspoon:
hs.hotkey.bind(
    {},
    "F18",
    function()
        -- Tap behaviour
    end
)

hs.hotkey.bind(
    hyper,
    "H",
    function()
        hs.alert.show("Hyper-H triggered!")
    end
)

-- F20 → toggle layer indicator (for testing)
hs.hotkey.bind({}, "f20", function()
    layerIndicator.toggle()
end)

  ------------------------------------------------------------
  -- ⌘Q/⌘W Hold-to-Quit/Close HUD (Dark Glass + Smooth Ghost Expand, FAST MODE)
  ------------------------------------------------------------

  -- ⏩ Timing: everything runs 2× faster
  local holdThreshold        = 0.5   -- was 1.0
  local ghostExpandDuration  = 0.175 -- was 0.35
  local totalDuration        = 0.7   -- overall fade cleanup window

  -- HUD sizing
  local frameSize, pad, circleYOff = 200, 30, -14
  local ghostMaxScale = 1.6

  -- State
  local indicator, progTimer = nil, nil
  local holding, quitTriggered, ghostActive = false, false, false
  local startTime, elapsed, lastTime = 0, 0, nil
  local appName = "App"
  local currentKey = nil  -- "q" or "w"
  local waitingForRelease = false  -- prevents re-trigger while held

  ------------------------------------------------------------
  -- STYLE
  ------------------------------------------------------------
  local glass = {
    bg     = { white = 0, alpha = 0.35 },
    border = { white = 1, alpha = 0.5 },
    text   = { white = 1, alpha = 0.9 },
  }

  ------------------------------------------------------------
  -- EASING
  ------------------------------------------------------------
  local function easeInOutCirc(t)
    t = math.min(math.max(t, 0), 1)
    if t < 0.5 then
      return (1 - math.sqrt(1 - (2 * t) ^ 2)) / 2
    else
      return (math.sqrt(1 - (-2 * t + 2) ^ 2) + 1) / 2
    end
  end

  local function easeOutExpo(t) return (t == 1) and 1 or (1 - 2 ^ (-10 * t)) end

  ------------------------------------------------------------
  -- HELPERS
  ------------------------------------------------------------
  local function safeDelete()
    hs.timer.doAfter(0.01, function()
      if indicator then indicator:delete() end
      indicator = nil
    end)
  end

  local function cleanup()
    if progTimer then progTimer:stop(); progTimer = nil end
    holding, quitTriggered, ghostActive = false, false, false
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
    local x = sf.x + (sf.w - frameSize) / 2
    local y = sf.y + (sf.h - frameSize) / 2
    appName = (hs.application.frontmostApplication() and hs.application.frontmostApplication():name()) or "App"

    local hudText = (currentKey == "q") and ("Quitting " .. appName) or "Closing"

    indicator = hs.canvas.new({ x = x, y = y, w = frameSize, h = frameSize }):show()
    indicator:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
    indicator:level(hs.canvas.windowLevels.cursor)

    local cx, cy = frameSize / 2, frameSize / 2
    local radius = (frameSize - pad * 2) / 3
    local rRadii = { xRadius = frameSize / 4, yRadius = frameSize / 4 }

    indicator[1] = { type = "rectangle", action = "fill",
      roundedRectRadii = rRadii, fillColor = glass.bg }

    indicator[2] = { type = "rectangle", action = "stroke",
      roundedRectRadii = rRadii, strokeColor = glass.border, strokeWidth = 1.2 }

    indicator[3] = { type = "arc", action = "fill",
      startAngle = -90, endAngle = -90,
      center = { x = cx, y = cy + circleYOff },
      radius = radius, fillColor = { white = 1, alpha = 0.95 } }

    indicator[4] = { type = "circle", action = "fill",
      center = { x = cx, y = cy + circleYOff },
      radius = radius, fillColor = { white = 1, alpha = 0 } }

    indicator[5] = { type = "text", text = hudText,
      textFont = "SF Pro Display Semibold", textSize = 16,
      textColor = glass.text,
      frame = { x = 0, y = cy + radius + circleYOff + 20,
                w = frameSize, h = 34 }, textAlignment = "center" }
  end

  ------------------------------------------------------------
  -- UPDATE LOOP (240 Hz)
  ------------------------------------------------------------
  local function update()
    if not indicator then return end
    local now = hs.timer.absoluteTime() / 1e9
    if not lastTime then lastTime = now end
    local delta = now - lastTime
    lastTime = now
    elapsed = elapsed + delta
    local phaseTime = elapsed

    if not quitTriggered then
      local pct = math.min(phaseTime / holdThreshold, 1)
      local eased = easeInOutCirc(pct)
      indicator[3].endAngle = -90 + (eased * 360)

      if pct >= 1 then
        quitTriggered = true
        waitingForRelease = true  -- prevent re-trigger until key released
        hs.timer.doAfter(0, function() hs.eventtap.keyStroke({ "cmd" }, currentKey, 0) end)
        indicator[3].fillColor.alpha = 0
        indicator[5].textColor.alpha = 0
        startTime, elapsed, ghostActive = now, 0, true
      end

    elseif ghostActive then
      local gt = math.min(phaseTime / ghostExpandDuration, 1)
      local eased = easeOutExpo(gt)
      local cx, cy = frameSize / 2, frameSize / 2
      local baseRadius = (frameSize - pad * 2) / 3
      local scale = 1 + (ghostMaxScale - 1) * eased
      local fade = 1 - eased

      indicator[4].radius = baseRadius * scale
      indicator[4].fillColor.alpha = fade * 0.8
      indicator[1].fillColor.alpha = glass.bg.alpha * fade
      indicator[2].strokeColor.alpha = glass.border.alpha * fade

      if gt >= 1 then cleanup() end
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
      if code == hs.keycodes.map.q and pureCmd then keyName = "q"
      elseif code == hs.keycodes.map.w and pureCmd then keyName = "w"
      end

      if not keyName then return false end

      if e:getType() == hs.eventtap.event.types.keyDown then
        -- Block if waiting for release
        if waitingForRelease then
          return true
        end

        if not holding then
          holding = true
          currentKey = keyName
          buildHUD()
          startTime = hs.timer.absoluteTime() / 1e9
          elapsed, lastTime = 0, nil
          progTimer = hs.timer.doEvery(1 / 240, update)
        end
        return true
      else
        -- keyUp
        if waitingForRelease then
          waitingForRelease = false
        end
        if holding and not quitTriggered then cleanup() end
        holding = false
        return true
      end
    end
  )
  tap:start()

  ------------------------------------------------------------
  -- TEST KEY (F19)
  ------------------------------------------------------------
  hs.hotkey.bind({}, "f19", function()
    if indicator then cleanup() end
    currentKey = "q"
    buildHUD()
    startTime = hs.timer.absoluteTime() / 1e9
    elapsed, quitTriggered, holding, lastTime, ghostActive = 0, false, true, nil, false
    progTimer = hs.timer.doEvery(1 / 240, update)
  end, cleanup)
------------------------------------------------------------
-- Focus Follows Mouse (with delay)
------------------------------------------------------------
local focusFollowsMouse = {
    delay = 0.05,  -- 50ms delay
    enabled = true,
    timer = nil,
    lastWindow = nil,
}

local function focusWindowUnderMouse()
    if not focusFollowsMouse.enabled then return end

    local win = hs.window.focusedWindow()
    local mousePos = hs.mouse.absolutePosition()
    local windowsUnderMouse = hs.fnutils.filter(hs.window.orderedWindows(), function(w)
        return w:isVisible() and w:isStandard() and w:frame():inside(hs.geometry.new(mousePos))
    end)

    local targetWindow = windowsUnderMouse[1]

    if targetWindow and targetWindow ~= win and targetWindow:id() ~= focusFollowsMouse.lastWindow then
        focusFollowsMouse.lastWindow = targetWindow:id()
        targetWindow:focus()
    end
end

local mouseMovedTap = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, function(e)
    if not focusFollowsMouse.enabled then return false end

    if focusFollowsMouse.timer then
        focusFollowsMouse.timer:stop()
    end

    focusFollowsMouse.timer = hs.timer.doAfter(focusFollowsMouse.delay, focusWindowUnderMouse)

    return false
end)

mouseMovedTap:start()

-- Toggle focus-follows-mouse with Hyper+F
hs.hotkey.bind(hyper, "F", function()
    focusFollowsMouse.enabled = not focusFollowsMouse.enabled
    hs.alert.show("Focus follows mouse: " .. (focusFollowsMouse.enabled and "ON" or "OFF"))
end)

------------------------------------------------------------
-- Finder to Bloom redirect
------------------------------------------------------------
require("finder_to_bloom")
