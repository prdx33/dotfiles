-- finder_to_bloom.lua
-- Redirects Finder dock icon clicks to open Bloom instead
--
-- How it works:
-- 1. Watches for Finder activation events
-- 2. When Finder activates from a "dock click" (no windows visible, user clicking dock)
-- 3. Immediately hides Finder and opens Bloom instead
--
-- Configuration: Change the targetApp variable below to use a different app

local M = {}

-- ============ CONFIGURATION ============
-- Change this to the app you want to open instead of Finder
local targetApp = "Bloom"

-- Set to true to show notifications when redirecting
local showNotifications = false

-- Cooldown in seconds to prevent rapid switching
local cooldownSeconds = 0.5
-- ========================================

local lastRedirectTime = 0
local finderWatcher = nil

-- Track if Finder was just hidden by us
local justHidFinder = false

local function log(msg)
    print("[FinderToBloom] " .. msg)
end

local function shouldRedirect()
    local now = hs.timer.secondsSinceEpoch()
    if (now - lastRedirectTime) < cooldownSeconds then
        return false
    end

    -- Don't redirect if we just hid Finder (prevents loops)
    if justHidFinder then
        justHidFinder = false
        return false
    end

    -- Check if any modifier keys are held (Cmd, Option, etc.)
    -- This allows Cmd+Click to still work normally for Finder menus
    local mods = hs.eventtap.checkKeyboardModifiers()
    if mods.cmd or mods.alt or mods.ctrl or mods.shift then
        return false
    end

    return true
end

local function redirectToBloom()
    if not shouldRedirect() then
        return
    end

    lastRedirectTime = hs.timer.secondsSinceEpoch()
    justHidFinder = true

    log("Redirecting to " .. targetApp)

    -- Hide Finder
    local finder = hs.application.get("Finder")
    if finder then
        finder:hide()
    end

    -- Open target app
    hs.application.launchOrFocus(targetApp)

    if showNotifications then
        hs.notify.new({title = "Finder → " .. targetApp, informativeText = "Opened " .. targetApp .. " instead of Finder"}):send()
    end
end

-- Watch for Finder activation
local function setupWatcher()
    finderWatcher = hs.application.watcher.new(function(appName, eventType, app)
        if appName == "Finder" and eventType == hs.application.watcher.activated then
            -- Small delay to let the activation complete, then redirect
            hs.timer.doAfter(0.05, function()
                redirectToBloom()
            end)
        end
    end)

    finderWatcher:start()
    log("Watcher started - clicking Finder dock icon will open " .. targetApp)
end

-- Cleanup function
function M.stop()
    if finderWatcher then
        finderWatcher:stop()
        finderWatcher = nil
        log("Watcher stopped")
    end
end

-- Allow changing the target app
function M.setTargetApp(appName)
    targetApp = appName
    log("Target app changed to: " .. appName)
end

-- Allow toggling notifications
function M.setNotifications(enabled)
    showNotifications = enabled
end

-- Initialize
setupWatcher()

-- Add menu bar indicator (optional - comment out if you don't want it)
-- M.menubar = hs.menubar.new()
-- M.menubar:setTitle("F→B")
-- M.menubar:setTooltip("Finder to Bloom redirect active")

return M
