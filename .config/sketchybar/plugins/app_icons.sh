#!/bin/bash

CUSTOM_ICONS="$HOME/.config/sketchybar/icons/tinyicon/24px"
CUSTOM_ICONS_DIM="$HOME/.config/sketchybar/icons/tinyicon/24px/dim25"
CUSTOM_ICONS_16="$HOME/.config/sketchybar/icons/tinyicon/16px"
# Auto-generated macOS icons (fallback when no manual icon exists)
MACOS_ICONS="$CUSTOM_ICONS/macos"
MACOS_ICONS_DIM="$CUSTOM_ICONS/macos/dim25"

# Map bundle IDs to custom icon filename
get_icon_name() {
    local bundle="$1"
    case "$bundle" in
        com.mitchellh.ghostty) echo "ghostty.png" ;;
        com.adobe.illustrator) echo "illustrator.png" ;;
        com.adobe.Photoshop) echo "photoshop.png" ;;
        com.spotify.client) echo "spotify.png" ;;
        md.obsidian) echo "obsidian.png" ;;
        com.tinyspeck.slackmacgap) echo "slack.png" ;;
        com.microsoft.VSCode) echo "vscode.png" ;;
        dev.warp.Warp-Stable) echo "warp.png" ;;
        com.raycast.macos) echo "raycast.png" ;;
        net.whatsapp.WhatsApp) echo "whatsapp.png" ;;
        com.openai.chat) echo "chatgpt.png" ;;
        com.anthropic.claudefordesktop) echo "claude.png" ;;
        com.apple.finder) echo "finder.png" ;;
        com.apple.TextEdit) echo "textedit.png" ;;
        com.readdle.smartemail-Mac) echo "spark.png" ;;
        com.asiafu.Bloom) echo "bloom.png" ;;
        org.mozilla.firefox) echo "firefox.png" ;;
        com.apple.Safari) echo "safari.png" ;;
        com.sublimetext.4) echo "sublimetext.png" ;;
        com.FormaGrid.Airtable) echo "airtable.png" ;;
        com.microsoft.Excel) echo "excel.png" ;;
        com.microsoft.Word) echo "word.png" ;;
        com.microsoft.Outlook) echo "outlook.png" ;;
        ai.elementlabs.lmstudio) echo "lmstudio.png" ;;
        org.pqrs.Karabiner-Elements.Settings) echo "karabiner.png" ;;
        com.googlecode.iterm2) echo "iterm2.png" ;;
        com.hnc.Discord) echo "discord.png" ;;
        com.todesktop.230313mzl4w4u92) echo "cursor.png" ;;
        com.figma.Desktop) echo "figma.png" ;;
        com.actualbudget.actual) echo "actual.png" ;;
        com.apple.Photos) echo "photos.png" ;;
        org.qbittorrent.qBittorrent) echo "qbittorrent.png" ;;
        ch.protonmail.desktop) echo "protonmail.png" ;;
        me.proton.pass.electron) echo "protonpass.png" ;;
        com.readdle.SparkDesktop.appstore) echo "sparkdesktop.png" ;;
        com.docker.docker) echo "docker.png" ;;
        com.brave.Browser) echo "brave.png" ;;
        com.apple.iCal) echo "calendar.png" ;;
        com.kakao.KakaoTalkMac) echo "kakaotalk.png" ;;
        com.apple.MobileSMS) echo "messages.png" ;;
        notion.id) echo "notion.png" ;;
        # macOS built-in apps
        com.apple.mail) echo "mail.png" ;;
        com.apple.Music) echo "music.png" ;;
        com.apple.Notes) echo "notes.png" ;;
        com.apple.Maps) echo "maps.png" ;;
        com.apple.FaceTime) echo "facetime.png" ;;
        com.apple.Preview) echo "preview.png" ;;
        com.apple.Terminal) echo "terminal.png" ;;
        com.apple.systempreferences) echo "systemsettings.png" ;;
        com.apple.AppStore) echo "appstore.png" ;;
        com.apple.AddressBook) echo "contacts.png" ;;
        com.apple.reminders) echo "reminders.png" ;;
        com.apple.news) echo "news.png" ;;
        com.apple.stocks) echo "stocks.png" ;;
        com.apple.podcasts) echo "podcasts.png" ;;
        com.apple.TV) echo "tv.png" ;;
        com.apple.iBooksX) echo "books.png" ;;
        com.apple.freeform) echo "freeform.png" ;;
        com.apple.Home) echo "home.png" ;;
        com.apple.weather) echo "weather.png" ;;
        com.apple.shortcuts) echo "shortcuts.png" ;;
        com.apple.calculator) echo "calculator.png" ;;
        com.apple.clock) echo "clock.png" ;;
        com.apple.ActivityMonitor) echo "activitymonitor.png" ;;
        com.apple.QuickTimePlayerX) echo "quicktime.png" ;;
        com.apple.VoiceMemos) echo "voicememos.png" ;;
        com.apple.findmy) echo "findmy.png" ;;
        com.apple.Passwords) echo "passwords.png" ;;
        com.apple.journal) echo "journal.png" ;;
        com.1password.1password) echo "1password.png" ;;
        com.Eltima.ElmediaPlayer) echo "elmediaplayer.png" ;;
        pro.betterdisplay.BetterDisplay) echo "betterdisplay.png" ;;
        com.sindresorhus.Color-Picker) echo "colorpicker.png" ;;
        org.hammerspoon.Hammerspoon) echo "hammerspoon.png" ;;
        com.sindresorhus.Color-Picker) echo "colorpicker.png" ;;
        com.google.Chrome) echo "google-chrome.png" ;;
        pl.maketheweb.cleanshotx) echo "cleanshotx.png" ;;
        com.dominiklevitsky.fontbase) echo "fontbase.png" ;;
        ru.keepcoder.Telegram) echo "telegram.png" ;;
        *) echo "" ;;
    esac
}

# Get icon path with appropriate dimming
# Priority: manual (24px/) > auto-generated (24px/macos/)
# Usage: get_custom_icon_dimmed <bundle_id> <state>
# State: focused | unfocused
get_custom_icon_dimmed() {
    local bundle="$1"
    local state="$2"
    local icon_name=$(get_icon_name "$bundle")

    [[ -z "$icon_name" ]] && echo "" && return

    case "$state" in
        focused)
            # Manual icon first, then macos fallback
            if [[ -f "$CUSTOM_ICONS/$icon_name" ]]; then
                echo "$CUSTOM_ICONS/$icon_name"
            elif [[ -f "$MACOS_ICONS/$icon_name" ]]; then
                echo "$MACOS_ICONS/$icon_name"
            fi
            ;;
        *)
            if [[ -f "$CUSTOM_ICONS_DIM/$icon_name" ]]; then
                echo "$CUSTOM_ICONS_DIM/$icon_name"
            elif [[ -f "$MACOS_ICONS_DIM/$icon_name" ]]; then
                echo "$MACOS_ICONS_DIM/$icon_name"
            fi
            ;;
    esac
}

# Icon for front app display (24px at 0.5 scale)
get_custom_icon() {
    local bundle="$1"
    local icon_name=$(get_icon_name "$bundle")
    [[ -n "$icon_name" && -f "$CUSTOM_ICONS/$icon_name" ]] && echo "$CUSTOM_ICONS/$icon_name" || echo ""
}

# Get list of apps on a workspace (unique, space-separated bundle IDs)
# Uses aerospace's native bundle ID output - no mdls lookup needed
get_workspace_apps() {
    local workspace="$1"
    aerospace list-windows --workspace "$workspace" --format "%{app-bundle-id}" 2>/dev/null | sort -u | tr '\n' ' ' | xargs
}

# Batch query: fetch all windows once (~22ms), then filter in bash (free)
# Call cache_all_workspace_apps once, then get_cached_workspace_apps per workspace
_ALL_WINDOWS_CACHE=""
_ALL_WINDOWS_LAYOUT_CACHE=""
cache_all_workspace_apps() {
    _ALL_WINDOWS_CACHE=$(aerospace list-windows --all --format '%{workspace}|%{app-bundle-id}' 2>/dev/null)
    _ALL_WINDOWS_LAYOUT_CACHE=$(aerospace list-windows --all --format '%{workspace}|%{window-layout}' 2>/dev/null)
}
get_cached_workspace_apps() {
    local workspace="$1"
    echo "$_ALL_WINDOWS_CACHE" | awk -F'|' -v ws="$workspace" '$1==ws{print $2}' | sort -u | tr '\n' ' ' | xargs
}
# Returns "1" if any window in workspace is tiled, "" otherwise
workspace_has_tiled() {
    local workspace="$1"
    echo "$_ALL_WINDOWS_LAYOUT_CACHE" | grep -q "^${workspace}|.*tiles" && echo "1"
}
