------------------------------------------------------------
-- WorkspaceHUD: Flash workspace letter on workspace change
-- Matches HoldToAction visual style (dark terminal aesthetic)
--
-- Usage (from shell):
--   hs -c 'WorkspaceHUD:show("Q", "floating")'
------------------------------------------------------------

local WorkspaceHUD = {}
WorkspaceHUD.__index = WorkspaceHUD

------------------------------------------------------------
-- STYLE (matches holdToAction)
------------------------------------------------------------

local style = {
  bg      = { red = 0.059, green = 0.075, blue = 0.102, alpha = 0.5 },
  text    = { white = 1, alpha = 0.8 },
  mint    = { red = 0.8, green = 1, blue = 0.9, alpha = 0.8 },
  peach   = { red = 1, green = 0.85, blue = 0.8, alpha = 0.8 },
  dim     = { white = 0.5, alpha = 1 },
}

local SIZE        = 160
local RADIUS      = 6
local SHOW_DELAY  = 0.05
local DISPLAY_SEC = 0.8
local FADE_SEC    = 0.3
local FPS         = 60
local FONT        = "Iosevka Extended Bold"

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------

local function now()
  return hs.timer.absoluteTime() / 1e9
end

local function focusedScreen()
  local win = hs.window.focusedWindow()
  return (win and win:screen()) or hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
end

------------------------------------------------------------
-- INIT
------------------------------------------------------------

function WorkspaceHUD:init()
  self.canvas = nil
  self.fadeTimer = nil
  self.dismissTimer = nil
  self.showTimer = nil
  return self
end

------------------------------------------------------------
-- CLEANUP
------------------------------------------------------------

function WorkspaceHUD:cleanup()
  if self.showTimer then
    self.showTimer:stop()
    self.showTimer = nil
  end
  if self.fadeInTimer then
    self.fadeInTimer:stop()
    self.fadeInTimer = nil
  end
  if self.fadeTimer then
    self.fadeTimer:stop()
    self.fadeTimer = nil
  end
  if self.dismissTimer then
    self.dismissTimer:stop()
    self.dismissTimer = nil
  end
  if self.canvas then
    pcall(function() self.canvas:delete() end)
    self.canvas = nil
  end
end

------------------------------------------------------------
-- SHOW (delayed to let monitor focus settle)
------------------------------------------------------------

function WorkspaceHUD:show(letter, layout)
  if not letter or letter == "" then return end
  self:cleanup()

  self.showTimer = hs.timer.doAfter(SHOW_DELAY, function()
    self:_render(letter, layout)
  end)
end

function WorkspaceHUD:_render(letter, layout)
  local scr = focusedScreen():fullFrame()
  local x = scr.x + (scr.w - SIZE) / 2
  local y = scr.y + 40

  local c = hs.canvas.new({ x = x, y = y, w = SIZE, h = SIZE })
  if not c then return end

  c:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
  c:level(hs.canvas.windowLevels.cursor)

  -- Resolve heading text and letter colour from layout
  local heading = "WORKSPACE"
  local letterColor = style.text
  if layout and layout ~= "" then
    if layout == "floating" then
      heading = "FLOATING"
      letterColor = style.mint
    else
      heading = "TILED"
      letterColor = style.peach
    end
  end

  -- Background
  c[1] = {
    type = "rectangle", action = "fill",
    frame = { x = 0, y = 0, w = SIZE, h = SIZE },
    roundedRectRadii = { xRadius = RADIUS, yRadius = RADIUS },
    fillColor = style.bg,
  }

  -- Heading: layout mode (white)
  c[2] = {
    type = "text",
    text = heading,
    textFont = FONT,
    textSize = 13,
    textColor = style.text,
    frame = { x = 0, y = SIZE * 0.08, w = SIZE, h = 20 },
    textAlignment = "center",
  }

  -- Large letter (vertically centred, colour-coded)
  c[3] = {
    type = "text",
    text = string.upper(letter),
    textFont = FONT,
    textSize = 84,
    textColor = letterColor,
    frame = { x = 0, y = SIZE * 0.22, w = SIZE, h = SIZE * 0.7 },
    textAlignment = "center",
  }

  c:alpha(0)
  c:show()
  self.canvas = c

  -- Fade in (0.2s quadratic ease-in)
  local FADE_IN_SEC = 0.2
  local fadeInStart = now()
  self.fadeInTimer = hs.timer.doEvery(1 / FPS, function()
    if not self.canvas then
      if self.fadeInTimer then self.fadeInTimer:stop(); self.fadeInTimer = nil end
      return
    end
    local t = math.min((now() - fadeInStart) / FADE_IN_SEC, 1)
    pcall(function() self.canvas:alpha(t * t) end)
    if t >= 1 then
      self.fadeInTimer:stop(); self.fadeInTimer = nil
    end
  end)

  -- Schedule fade out after fade-in + display
  self.dismissTimer = hs.timer.doAfter(FADE_IN_SEC + DISPLAY_SEC, function()
    self:fade()
  end)
end

------------------------------------------------------------
-- FADE (clean ease-out)
------------------------------------------------------------

function WorkspaceHUD:fade()
  if not self.canvas then return end
  local fadeStart = now()

  self.fadeTimer = hs.timer.doEvery(1 / FPS, function()
    if not self.canvas then
      if self.fadeTimer then self.fadeTimer:stop(); self.fadeTimer = nil end
      return
    end

    local t = (now() - fadeStart) / FADE_SEC
    if t > 1 then t = 1 end

    local alpha = 1 - (t * t)

    if t >= 1 then
      self:cleanup()
    else
      pcall(function()
        self.canvas:alpha(alpha)
      end)
    end
  end)
end

return WorkspaceHUD
