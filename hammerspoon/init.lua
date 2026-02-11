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

-- Icon map: bundle ID → tinyicon filename (mirrors app_icons.sh)
local ICON_DIR = os.getenv("HOME") .. "/.config/sketchybar/icons/tinyicon/500px"
local ICON_MAP = {
  ["com.mitchellh.ghostty"] = "ghostty", ["com.spotify.client"] = "spotify",
  ["md.obsidian"] = "obsidian", ["com.tinyspeck.slackmacgap"] = "slack",
  ["com.microsoft.VSCode"] = "vscode", ["dev.warp.Warp-Stable"] = "warp",
  ["com.raycast.macos"] = "raycast", ["net.whatsapp.WhatsApp"] = "whatsapp",
  ["com.openai.chat"] = "chatgpt", ["com.anthropic.claudefordesktop"] = "claude",
  ["com.apple.finder"] = "finder", ["com.apple.Safari"] = "safari",
  ["org.mozilla.firefox"] = "firefox", ["com.apple.TextEdit"] = "textedit",
  ["com.readdle.smartemail-Mac"] = "spark", ["com.asiafu.Bloom"] = "bloom",
  ["com.sublimetext.4"] = "sublimetext", ["com.FormaGrid.Airtable"] = "airtable",
  ["com.microsoft.Excel"] = "excel", ["com.microsoft.Word"] = "word",
  ["com.microsoft.Outlook"] = "outlook", ["ai.elementlabs.lmstudio"] = "lmstudio",
  ["org.pqrs.Karabiner-Elements.Settings"] = "karabiner",
  ["com.googlecode.iterm2"] = "iterm2", ["com.hnc.Discord"] = "discord",
  ["com.todesktop.230313mzl4w4u92"] = "cursor", ["com.figma.Desktop"] = "figma",
  ["com.actualbudget.actual"] = "actual", ["com.apple.Photos"] = "photos",
  ["org.qbittorrent.qBittorrent"] = "qbittorrent",
  ["ch.protonmail.desktop"] = "protonmail", ["me.proton.pass.electron"] = "protonpass",
  ["com.readdle.SparkDesktop.appstore"] = "sparkdesktop",
  ["com.docker.docker"] = "docker", ["com.brave.Browser"] = "brave",
  ["com.apple.iCal"] = "calendar", ["com.kakao.KakaoTalkMac"] = "kakaotalk",
  ["com.apple.MobileSMS"] = "messages", ["notion.id"] = "notion",
  ["com.apple.mail"] = "mail", ["com.apple.Music"] = "music",
  ["com.apple.Notes"] = "notes", ["com.apple.Maps"] = "maps",
  ["com.apple.Preview"] = "preview", ["com.apple.Terminal"] = "terminal",
  ["com.apple.systempreferences"] = "systemsettings",
  ["com.apple.AppStore"] = "appstore", ["com.apple.AddressBook"] = "contacts",
  ["com.apple.reminders"] = "reminders", ["com.apple.ActivityMonitor"] = "activitymonitor",
  ["com.adobe.illustrator"] = "illustrator", ["com.adobe.Photoshop"] = "photoshop",
  ["com.1password.1password"] = "1password", ["com.Eltima.ElmediaPlayer"] = "elmediaplayer",
}

local function resolveAppIcon(bundleID)
  if not bundleID then return nil end
  local name = ICON_MAP[bundleID]
  if not name then return nil end
  local path = ICON_DIR .. "/" .. name .. ".png"
  if hs.fs.attributes(path) then return path end
  -- Try macos auto-generated fallback
  path = ICON_DIR .. "/macos/" .. name .. ".png"
  if hs.fs.attributes(path) then return path end
  return nil
end

local holdToQuit = HoldToAction.new({
  name = "HoldToQuit",
  keycode = hs.keycodes.map.q,
  holdThreshold = 0.5,
  fadeDelay = 0.3,
  fadeDuration = 0.7,
  updateRate = 60,
  cooldown = 0,
  hudWidth = 200,
  hudHeight = 200,
  barHeight = 4,
  barPadding = 24,
  hudIconSize = 64,
  maxTitleLength = nil,
  hudTitle = "Quitting",
  hudPrefix = "",
  onKeyUpDuringFade = "await_release",

  onCaptureTarget = function(self)
    local app = hs.application.frontmostApplication()
    self.state.displayLabel = (app and app:name()) or "App"
    if app then
      self.state.iconPath = resolveAppIcon(app:bundleID())
    end
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
  holdThreshold = 0.3,
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
