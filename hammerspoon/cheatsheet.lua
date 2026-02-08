------------------------------------------------------------
-- AeroSpace/Karabiner/Rectangle Cheatsheet Overlay
-- Triggered by F10, dismiss with any key or click
------------------------------------------------------------

local Cheatsheet = {}

-- Style (matches HoldToQuit)
Cheatsheet.style = {
  bg = { white = 0.1, alpha = 0.92 },
  text = { white = 0.9, alpha = 1 },
  dim = { white = 0.5, alpha = 1 },
  accent = { red = 1, green = 0.75, blue = 0.3, alpha = 1 },
  mint = { red = 0.6, green = 1, blue = 0.8, alpha = 1 },
}

Cheatsheet.config = {
  width = 620,
  padding = 24,
  lineHeight = 20,
  sectionGap = 12,
  headerSize = 13,
  textSize = 12,
  font = "JetBrains Mono",
}

-- State
Cheatsheet.canvas = nil
Cheatsheet.dismissTap = nil
Cheatsheet.fadeTimer = nil
Cheatsheet.visible = false

-- Shortcut data
Cheatsheet.sections = {
  {
    title = "HYPER — Float Mode (default)",
    items = {
      { "Q", "Cascade all windows" },
      { "W", "Focus prev window" },
      { "E", "Maximize" },
      { "R", "Focus next window" },
      { "T", "Focus next monitor" },
      { "S", "Snap left ½ → ⅓ cycle" },
      { "D", "Snap center ½ → ⅓ cycle" },
      { "F", "Snap right ½ → ⅓ cycle" },
      { "X", "Snap left ⅔" },
      { "C", "Snap center ⅔" },
      { "V", "Snap right ⅔" },
    }
  },
  {
    title = "HYPER — Tile Mode (opt-in via Z)",
    items = {
      { "W", "Focus prev window" },
      { "E", "Move up" },
      { "R", "Focus next window" },
      { "S", "Move left" },
      { "D", "Move down" },
      { "F", "Move right" },
      { "X", "Shrink window" },
      { "C", "Flatten + horizontal tiles" },
      { "V", "Grow window" },
    }
  },
  {
    title = "HYPER — Both Modes",
    items = {
      { "A", "Toggle ALL windows float/tile" },
      { "Z", "Toggle focused window float/tile" },
      { "G", "Move window to next monitor" },
      { "B", "Swap monitor workspaces" },
      { "/", "Sort windows by app" },
      { ";", "Service mode" },
      { "'", "Toggle SketchyBar" },
    }
  },
  {
    title = "ALT (⌥) — Workspaces",
    items = {
      { "A", "Slack" },
      { "B", "Bloom" },
      { "C", "Claude" },
      { "D", "Obsidian" },
      { "F", "Firefox / Safari / Brave" },
      { "G", "Ghostty / Terminal / Warp" },
      { "I", "System Settings" },
      { "K", "Karabiner" },
      { "L", "LM Studio" },
      { "M", "Messages" },
      { "O", "Outlook" },
      { "P", "Photos" },
      { "R", "Spark" },
      { "S", "Spotify / Music" },
      { "T", "Sublime Text" },
      { "V", "VS Code / Cursor" },
      { "W", "WhatsApp" },
    }
  },
  {
    title = "ALT+SHIFT (⌥⇧) — Send Window",
    items = {
      { "A-Z", "Send window to workspace (stay on current)" },
    }
  },
  {
    title = "SERVICE MODE (Hyper ;)",
    items = {
      { "Esc", "Exit" },
      { "R", "Reload config" },
      { "D", "Enable/disable AeroSpace" },
      { "F", "Flatten workspace tree" },
      { "Q", "Close all but current" },
    }
  },
  {
    title = "HAMMERSPOON",
    items = {
      { "⌘Q hold", "Hold-to-quit" },
      { "⌘W hold", "Hold-to-close" },
      { "⌘M", "Minimise toggle" },
      { "F10", "This cheatsheet" },
    }
  },
}

function Cheatsheet:calculateHeight()
  local cfg = self.config
  local height = cfg.padding * 2  -- top and bottom padding

  for i, section in ipairs(self.sections) do
    height = height + cfg.lineHeight  -- section header
    height = height + (#section.items * cfg.lineHeight)
    if i < #self.sections then
      height = height + cfg.sectionGap
    end
  end

  return height
end

function Cheatsheet:createCanvas()
  local cfg = self.config
  local height = self:calculateHeight()

  local screen = hs.screen.mainScreen():fullFrame()
  local x = screen.x + (screen.w - cfg.width) / 2
  local y = screen.y + (screen.h - height) / 2

  local canvas = hs.canvas.new({ x = x, y = y, w = cfg.width, h = height })
  canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
  canvas:level(hs.canvas.windowLevels.modalPanel)

  local elements = {}

  -- Background
  table.insert(elements, {
    type = "rectangle",
    action = "fill",
    roundedRectRadii = { xRadius = 10, yRadius = 10 },
    fillColor = self.style.bg,
  })

  -- Border
  table.insert(elements, {
    type = "rectangle",
    action = "stroke",
    roundedRectRadii = { xRadius = 10, yRadius = 10 },
    strokeColor = { white = 0.3, alpha = 0.5 },
    strokeWidth = 1,
  })

  local yPos = cfg.padding
  local keyColWidth = 100

  for i, section in ipairs(self.sections) do
    -- Section header
    table.insert(elements, {
      type = "text",
      text = section.title,
      textFont = cfg.font,
      textSize = cfg.headerSize,
      textColor = self.style.accent,
      frame = { x = cfg.padding, y = yPos, w = cfg.width - cfg.padding * 2, h = cfg.lineHeight },
    })
    yPos = yPos + cfg.lineHeight

    -- Items
    for _, item in ipairs(section.items) do
      -- Key
      table.insert(elements, {
        type = "text",
        text = item[1],
        textFont = cfg.font,
        textSize = cfg.textSize,
        textColor = self.style.mint,
        frame = { x = cfg.padding, y = yPos, w = keyColWidth, h = cfg.lineHeight },
      })
      -- Description
      table.insert(elements, {
        type = "text",
        text = item[2],
        textFont = cfg.font,
        textSize = cfg.textSize,
        textColor = self.style.text,
        frame = { x = cfg.padding + keyColWidth, y = yPos, w = cfg.width - cfg.padding * 2 - keyColWidth, h = cfg.lineHeight },
      })
      yPos = yPos + cfg.lineHeight
    end

    if i < #self.sections then
      yPos = yPos + cfg.sectionGap
    end
  end

  -- Add all elements
  for _, el in ipairs(elements) do
    canvas:appendElements(el)
  end

  return canvas
end

function Cheatsheet:stopFadeTimer()
  if self.fadeTimer then
    self.fadeTimer:stop()
    self.fadeTimer = nil
  end
end

function Cheatsheet:show()
  if self.visible then return end

  self:stopFadeTimer()
  self.canvas = self:createCanvas()
  self.canvas:alpha(0)
  self.canvas:show()

  -- Fade in
  local alpha = 0
  self.fadeTimer = hs.timer.doEvery(0.016, function(timer)
    alpha = alpha + 0.1
    if alpha >= 1 then
      alpha = 1
      self:stopFadeTimer()
    end
    if self.canvas then
      self.canvas:alpha(alpha)
    else
      self:stopFadeTimer()
    end
  end)

  self.visible = true

  -- Dismiss on any key or click
  self.dismissTap = hs.eventtap.new(
    { hs.eventtap.event.types.keyDown, hs.eventtap.event.types.leftMouseDown },
    function(e)
      self:hide()
      return true
    end
  )
  self.dismissTap:start()
end

function Cheatsheet:hide()
  if not self.visible then return end

  if self.dismissTap then
    self.dismissTap:stop()
    self.dismissTap = nil
  end

  self:stopFadeTimer()

  if self.canvas then
    -- Fade out
    local alpha = 1
    self.fadeTimer = hs.timer.doEvery(0.016, function(timer)
      alpha = alpha - 0.15
      if alpha <= 0 then
        self:stopFadeTimer()
        if self.canvas then
          self.canvas:delete()
          self.canvas = nil
        end
      else
        if self.canvas then
          self.canvas:alpha(alpha)
        else
          self:stopFadeTimer()
        end
      end
    end)
  end

  self.visible = false
end

function Cheatsheet:toggle()
  if self.visible then
    self:hide()
  else
    self:show()
  end
end

return Cheatsheet
