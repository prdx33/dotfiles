------------------------------------------------------------
-- ZMK Layer Indicator
--
-- Large arrow indicator centred (20% below middle) on all screens.
-- ZMK sends F13 on layer toggle → Hammerspoon shows/hides arrow.
-- Fades in at 80% opacity, then settles to 30% over 2 seconds.
--
-- API:
--   layerIndicator.toggle()     - flip state (used by F13)
--   layerIndicator.show()       - force visible
--   layerIndicator.hide()       - force hidden
--   layerIndicator.setSymbol(s) - change symbol (default: ↑)
------------------------------------------------------------

local M = {}

------------------------------------------------------------
-- CONFIGURATION
------------------------------------------------------------
local config = {
    animationDuration = 0.12,   -- fade in/out duration
    settleDuration = 2.0,       -- time to fade to settled opacity
    settledAlpha = 0.30,        -- opacity after settling
    fullAlpha = 0.80,           -- initial full opacity
    symbol = "↑",               -- arrow up
    fontSize = 200,
}

------------------------------------------------------------
-- STYLE (minimal terminal green)
------------------------------------------------------------
local style = {
    color = { red = 0.2, green = 1.0, blue = 0.4, alpha = 0.80 },  -- bright terminal green
}

------------------------------------------------------------
-- STATE
------------------------------------------------------------
local state = {
    inToggledLayer = false,
    canvases = {},              -- one canvas per screen
    animationTimer = nil,
    animationDirection = nil,   -- "show" or "hide" or "settle" or nil
    settleTimer = nil,          -- timer for settle animation
    currentAlpha = 0,           -- track alpha for all canvases
}

-- Hotkey and watcher references
local signalHotkey = nil
local screenWatcher = nil

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------
local function easeOutExpo(t)
    return (t == 1) and 1 or (1 - 2 ^ (-10 * t))
end

------------------------------------------------------------
-- OVERLAY CREATION
------------------------------------------------------------
local function createOverlayForScreen(screen)
    local frame = screen:fullFrame()
    local size = config.fontSize + 8

    -- Position: centred horizontally, 20% below centre vertically
    local x = frame.x + (frame.w - size) / 2
    local y = frame.y + (frame.h - size) / 2 + (frame.h * 0.20)

    local canvas = hs.canvas.new({ x = x, y = y, w = size, h = size })

    -- Simple bold arrow symbol
    canvas[1] = {
        type = "text",
        text = config.symbol,
        textFont = "Menlo Bold",
        textSize = config.fontSize,
        textColor = style.color,
        frame = { x = 0, y = 2, w = size, h = size },
        textAlignment = "center",
    }

    canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
    canvas:level(hs.canvas.windowLevels.overlay)

    return canvas
end

------------------------------------------------------------
-- ANIMATION HELPERS
------------------------------------------------------------
local function stopAnimation()
    if state.animationTimer then
        state.animationTimer:stop()
        state.animationTimer = nil
    end
    if state.settleTimer then
        state.settleTimer:stop()
        state.settleTimer = nil
    end
    state.animationDirection = nil
end

local function deleteAllCanvases()
    for _, canvas in pairs(state.canvases) do
        if canvas then canvas:delete() end
    end
    state.canvases = {}
    state.currentAlpha = 0
end

local function createAllCanvases()
    deleteAllCanvases()
    for _, screen in ipairs(hs.screen.allScreens()) do
        local canvas = createOverlayForScreen(screen)
        canvas:alpha(0)
        canvas:show()
        state.canvases[screen:id()] = canvas
    end
end

local function setAllAlpha(alpha)
    state.currentAlpha = alpha
    for _, canvas in pairs(state.canvases) do
        if canvas then canvas:alpha(alpha) end
    end
end

------------------------------------------------------------
-- SETTLE ANIMATION (fade from full to 30% over 2 seconds)
------------------------------------------------------------
local function startSettleAnimation()
    local startTime = hs.timer.absoluteTime() / 1e9
    local startAlpha = config.fullAlpha
    local targetAlpha = config.settledAlpha
    state.animationDirection = "settle"

    state.settleTimer = hs.timer.doEvery(1/60, function()
        if state.animationDirection ~= "settle" then return end

        local elapsed = (hs.timer.absoluteTime() / 1e9) - startTime
        local progress = math.min(elapsed / config.settleDuration, 1)
        local eased = easeOutExpo(progress)
        local alpha = startAlpha - (startAlpha - targetAlpha) * eased

        setAllAlpha(alpha)

        if progress >= 1 then
            if state.settleTimer then
                state.settleTimer:stop()
                state.settleTimer = nil
            end
            state.animationDirection = nil
            setAllAlpha(targetAlpha)
        end
    end)
end

------------------------------------------------------------
-- SHOW / HIDE ANIMATIONS
------------------------------------------------------------
local function showOverlay()
    -- Cancel any running animation
    stopAnimation()

    -- Create canvases for all screens if needed
    if next(state.canvases) == nil then
        createAllCanvases()
    end

    local startTime = hs.timer.absoluteTime() / 1e9
    local startAlpha = state.currentAlpha
    local targetAlpha = config.fullAlpha
    local duration = config.animationDuration * (targetAlpha - startAlpha) / targetAlpha
    state.animationDirection = "show"

    if duration < 0.01 then
        setAllAlpha(targetAlpha)
        startSettleAnimation()
        return
    end

    state.animationTimer = hs.timer.doEvery(1/60, function()
        if state.animationDirection ~= "show" then return end

        local elapsed = (hs.timer.absoluteTime() / 1e9) - startTime
        local progress = math.min(elapsed / duration, 1)
        local eased = easeOutExpo(progress)
        local alpha = startAlpha + (targetAlpha - startAlpha) * eased

        setAllAlpha(alpha)

        if progress >= 1 then
            if state.animationTimer then
                state.animationTimer:stop()
                state.animationTimer = nil
            end
            -- Start the settle animation to fade to 30%
            startSettleAnimation()
        end
    end)
end

local function hideOverlay()
    if next(state.canvases) == nil then return end

    -- Cancel any running animation
    stopAnimation()

    local startTime = hs.timer.absoluteTime() / 1e9
    local startAlpha = state.currentAlpha
    local duration = 0.12 * startAlpha
    state.animationDirection = "hide"

    if duration < 0.01 then
        deleteAllCanvases()
        return
    end

    state.animationTimer = hs.timer.doEvery(1/60, function()
        if state.animationDirection ~= "hide" then return end

        local elapsed = (hs.timer.absoluteTime() / 1e9) - startTime
        local progress = math.min(elapsed / duration, 1)
        local eased = easeOutExpo(progress)
        local alpha = startAlpha * (1 - eased)

        setAllAlpha(alpha)

        if progress >= 1 then
            stopAnimation()
            deleteAllCanvases()
        end
    end)
end

------------------------------------------------------------
-- REPOSITION (for screen changes)
------------------------------------------------------------
local function repositionOverlays()
    if next(state.canvases) == nil then return end

    -- Recreate canvases for new screen configuration
    local alpha = state.currentAlpha
    createAllCanvases()
    setAllAlpha(alpha)
end

------------------------------------------------------------
-- LAYER TOGGLE
------------------------------------------------------------
local function onLayerSignal()
    state.inToggledLayer = not state.inToggledLayer
    if state.inToggledLayer then
        showOverlay()
    else
        hideOverlay()
    end
end

------------------------------------------------------------
-- CLEANUP
------------------------------------------------------------
local function cleanup()
    if signalHotkey then
        signalHotkey:delete()
        signalHotkey = nil
    end
    if screenWatcher then
        screenWatcher:stop()
        screenWatcher = nil
    end
    stopAnimation()
    deleteAllCanvases()
    state.inToggledLayer = false
end

------------------------------------------------------------
-- PUBLIC API
------------------------------------------------------------
function M.start()
    -- Listen for F13 from ZMK keyboard
    signalHotkey = hs.hotkey.bind({}, "f13", function()
        onLayerSignal()
    end)

    -- Recreate overlays if screen configuration changes
    screenWatcher = hs.screen.watcher.new(function()
        repositionOverlays()
    end)
    screenWatcher:start()
end

function M.stop()
    cleanup()
end

-- Toggle state (used by F13 signal and F20 test key)
function M.toggle()
    onLayerSignal()
end

-- Force show overlay (for manual sync if state drifts)
function M.show()
    if not state.inToggledLayer then
        state.inToggledLayer = true
        showOverlay()
    end
end

-- Force hide overlay (for manual sync if state drifts)
function M.hide()
    if state.inToggledLayer then
        state.inToggledLayer = false
        hideOverlay()
    end
end

function M.isInToggledLayer()
    return state.inToggledLayer
end

function M.setSymbol(symbol)
    config.symbol = symbol
    -- Recreate canvases if currently visible
    if next(state.canvases) ~= nil then
        local alpha = state.currentAlpha
        createAllCanvases()
        setAllAlpha(alpha)
    end
end

return M
