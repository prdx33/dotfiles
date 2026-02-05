------------------------------------------------------------
-- IPC (enables CLI access via `hs` command)
------------------------------------------------------------
require("hs.ipc")

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

-- ⌘M → minimise toggle
hs.hotkey.bind({"cmd"}, "m", wm.toggleMinimize)

------------------------------------------------------------
-- Hold-to-Action: ⌘Q (quit app) and ⌘W (close window)
-- Single eventtap, shared watchdog, shared caffeinate watcher
------------------------------------------------------------
package.loaded["holdToAction"] = nil  -- force reload on config reload
local HoldToAction = require("holdToAction")

local holdToQuit = HoldToAction.new({
  name = "HoldToQuit",
  keycode = hs.keycodes.map.q,
  holdThreshold = 0.5,
  fadeDelay = 0.5,
  fadeDuration = 0.15,
  updateRate = 60,
  cooldown = 0,
  hudWidth = 220,
  hudHeight = 60,
  barHeight = 4,
  barPadding = 16,
  maxTitleLength = nil,
  hudPrefix = "Quitting ",
  onKeyUpDuringFade = "await_release",

  onCaptureTarget = function(self)
    local app = hs.application.frontmostApplication()
    self.state.displayLabel = (app and app:name()) or "App"
    return true
  end,

  onTrigger = function(self)
    local app = hs.application.frontmostApplication()
    if app then
      local name = app:name() or "unknown"
      if name == "Finder" then
        self:log("Blocked quit for Finder")
      else
        self:log("Killing app: " .. name)
        app:kill()
      end
    end
  end,

  onShiftAction = function(self)
    local app = hs.application.frontmostApplication()
    if app and app:name() ~= "Finder" then
      self:log("Instant quit (Shift+Cmd+Q): " .. (app:name() or "App"))
      app:kill()
    end
    return true
  end,
})

local holdToClose = HoldToAction.new({
  name = "HoldToClose",
  keycode = hs.keycodes.map.w,
  holdThreshold = 0.4,
  fadeDelay = 0.3,
  fadeDuration = 0.15,
  updateRate = 60,
  cooldown = 0.5,
  hudWidth = 260,
  hudHeight = 60,
  barHeight = 4,
  barPadding = 16,
  maxTitleLength = 28,
  hudPrefix = "Closing ",
  onKeyUpDuringFade = "reset_idle",

  onCaptureTarget = function(self)
    local win = hs.window.frontmostWindow()
    if not win then
      self:log("No frontmost window to close")
      return false
    end
    self.state.targetWindowId = win:id()
    self.state.displayLabel = win:title() or "Window"
    self:log("Targeting window: " .. self.state.displayLabel
      .. " (ID: " .. tostring(self.state.targetWindowId) .. ")")
    return true
  end,

  onTrigger = function(self)
    self:log("Closing window: " .. (self.state.displayLabel or "unknown")
      .. " - sending Cmd+W keystroke")
    self.passthroughCount = 2  -- keyDown + keyUp from synthesised keystroke
    hs.eventtap.keyStroke({"cmd"}, "w", 0)
  end,

  onShiftAction = function(self)
    local win = hs.window.frontmostWindow()
    if win then
      self:log("Nuclear close (Shift+Cmd+W): " .. (win:title() or "Window"))
      win:close()
    end
    return true
  end,
})

local holdDispatcher = HoldToAction.createDispatcher({
  [hs.keycodes.map.q] = holdToQuit,
  [hs.keycodes.map.w] = holdToClose,
})
holdDispatcher:start()

------------------------------------------------------------
-- Bar Toggle - Alternate between SketchyBar and macOS menu bar
-- Called via: hs -c 'BarToggle:toggle()'
------------------------------------------------------------
package.loaded["barToggle"] = nil  -- force reload on config reload
BarToggle = require("barToggle")   -- global for CLI access
BarToggle:init()
