------------------------------------------------------------
-- Bar Fade — Black overlay that dims SketchyBar on idle
--
-- Creates a canvas rectangle over the menu bar area on each
-- screen. Fades from 0 to 80% opacity over 1s after idle
-- threshold. Fades out immediately on mouse/keyboard activity.
-- Canvas is click-through (no mouse callback registered).
------------------------------------------------------------

local barFade = {}

barFade.IDLE_THRESHOLD = 8      -- seconds before fade starts
barFade.FADE_DURATION  = 1.0    -- seconds for full fade-in
barFade.UNFADE_DURATION = 0.3   -- seconds for fade-out (snappy)
barFade.TARGET_ALPHA   = 0.80   -- max overlay opacity
barFade.CHECK_INTERVAL = 2      -- idle check frequency
barFade.ANIM_FPS       = 30     -- animation frame rate
barFade.BAR_HEIGHT     = 30     -- sketchybar bar height

barFade.overlays = {}
barFade.currentAlpha = 0
barFade.animTimer = nil
barFade.checkTimer = nil
barFade.faded = false
barFade.screenWatcher = nil

function barFade:createOverlays()
    self:destroyOverlays()

    for _, screen in ipairs(hs.screen.allScreens()) do
        local frame = screen:fullFrame()
        local overlay = hs.canvas.new({
            x = frame.x,
            y = frame.y,
            w = frame.w,
            h = self.BAR_HEIGHT,
        })

        overlay:appendElements({
            type = "rectangle",
            fillColor = { black = 1, alpha = 0 },
            action = "fill",
        })

        -- Above sketchybar (topmost), click-through (no mouse callback)
        overlay:level(hs.canvas.windowLevels.screenSaver)
        overlay:behavior(
            hs.canvas.windowBehaviors.canJoinAllSpaces +
            hs.canvas.windowBehaviors.stationary
        )
        overlay:clickActivating(false)
        overlay:show()

        table.insert(self.overlays, overlay)
    end
end

function barFade:destroyOverlays()
    for _, overlay in ipairs(self.overlays) do
        overlay:delete()
    end
    self.overlays = {}
end

function barFade:setAlpha(alpha)
    self.currentAlpha = alpha
    for _, overlay in ipairs(self.overlays) do
        overlay:elementAttribute(1, "fillColor", { black = 1, alpha = alpha })
    end
end

function barFade:animateTo(target, duration)
    if self.animTimer then
        self.animTimer:stop()
        self.animTimer = nil
    end

    local steps = math.max(1, math.floor(duration * self.ANIM_FPS))
    local startAlpha = self.currentAlpha
    local step = 0

    self.animTimer = hs.timer.doEvery(1 / self.ANIM_FPS, function()
        step = step + 1
        if step >= steps then
            self:setAlpha(target)
            if self.animTimer then
                self.animTimer:stop()
                self.animTimer = nil
            end
        else
            -- Ease-in curve for fade-in (slow start, fast end)
            local t = step / steps
            if target > startAlpha then
                t = t * t  -- quadratic ease-in
            end
            self:setAlpha(startAlpha + (target - startAlpha) * t)
        end
    end)
end

function barFade:fadeIn()
    if self.faded then return end
    self.faded = true
    self:animateTo(self.TARGET_ALPHA, self.FADE_DURATION)
end

function barFade:fadeOut()
    if not self.faded then return end
    self.faded = false
    self:animateTo(0, self.UNFADE_DURATION)
end

function barFade:checkIdle()
    local idle = hs.host.idleTime()
    if idle >= self.IDLE_THRESHOLD then
        self:fadeIn()
    else
        self:fadeOut()
    end
end

function barFade:init()
    self:createOverlays()

    -- Periodic idle check
    self.checkTimer = hs.timer.doEvery(self.CHECK_INTERVAL, function()
        self:checkIdle()
    end)

    -- Recreate overlays on screen layout change
    self.screenWatcher = hs.screen.watcher.new(function()
        self:createOverlays()
        if self.faded then
            self:setAlpha(self.TARGET_ALPHA)
        end
    end)
    self.screenWatcher:start()

    print("[barFade] Ready (idle: " .. self.IDLE_THRESHOLD .. "s, target: " .. (self.TARGET_ALPHA * 100) .. "%)")
end

function barFade:stop()
    if self.checkTimer then self.checkTimer:stop() end
    if self.animTimer then self.animTimer:stop() end
    if self.screenWatcher then self.screenWatcher:stop() end
    self:destroyOverlays()
end

return barFade
