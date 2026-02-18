#!/bin/bash

# Optimised workspace change handler - only updates prev + current workspace
# Split layout: left group | divider | right group (all center position)

# Exclusive lock + event coalescing — prevents zombie accumulation
LOCKDIR="/tmp/aerospace_change.lock"
TOUCHED="/tmp/aerospace_change.touched"

[[ -n "$PREV" ]] && echo "$PREV" >> "$TOUCHED"
[[ -n "$FOCUSED" ]] && echo "$FOCUSED" >> "$TOUCHED"

if ! mkdir "$LOCKDIR" 2>/dev/null; then
    OLD_PID=$(cat "$LOCKDIR/pid" 2>/dev/null)
    if [[ -n "$OLD_PID" ]] && kill -0 "$OLD_PID" 2>/dev/null; then
        exit 0
    fi
    rm -rf "$LOCKDIR"
    mkdir "$LOCKDIR" 2>/dev/null || exit 0
fi
echo $$ > "$LOCKDIR/pid"
trap 'rm -rf "$LOCKDIR"' EXIT

sleep 0.03
TOUCHED_WS=$(sort -u "$TOUCHED" 2>/dev/null | tr '\n' ' ')
rm -f "$TOUCHED"

CONFIG_DIR="$HOME/.config/sketchybar"
source "$CONFIG_DIR/colours.sh" 2>/dev/null || exit 0
source "$CONFIG_DIR/plugins/app_icons.sh" 2>/dev/null

# === Grid model — must match aerospace_refresh.sh ===
# CRITICAL: padding does NOT affect center layout flow — only width does.
MAX_ICONS=4
FONT_SIZE=10.0
ICON_SCALE=0.38
CELL=20
WORKSPACE_GAP=20
M1_TEXT_SHIFT=-10
MONO_FONT="Iosevka Extended"

m1_ws=$(aerospace list-workspaces --monitor 1 --visible 2>/dev/null | xargs)
m2_ws=$(aerospace list-workspaces --monitor 2 --visible 2>/dev/null | xargs)
focused_ws=$(aerospace list-workspaces --focused 2>/dev/null | xargs)

cache_all_workspace_apps

BATCH_CMD="sketchybar"

PREV_STATE="/tmp/sketchybar_highlighted"
PREV_HIGHLIGHTED=$(cat "$PREV_STATE" 2>/dev/null)

_seen=" "
for ws in $TOUCHED_WS $m1_ws $m2_ws $PREV_HIGHLIGHTED; do
    [[ -z "$ws" ]] && continue
    case "$_seen" in *" $ws "*) continue ;; esac
    _seen="$_seen$ws "

    local_bundles=$(get_cached_workspace_apps "$ws")
    IFS=' ' read -ra BUNDLES <<< "$local_bundles"
    num_apps=${#BUNDLES[@]}

    icon_prefix=""
    icon_suffix=""
    [[ "$ws" == "$m1_ws" ]] && icon_prefix="◂"
    [[ "$ws" == "$m2_ws" ]] && icon_suffix="▸"

    if [[ "$ws" == "$focused_ws" ]]; then
        icon_font="$MONO_FONT:Heavy:$FONT_SIZE"
        icon_color=$WS_FOCUSED
        icon_state="focused"
    elif [[ "$ws" == "$m1_ws" || "$ws" == "$m2_ws" ]]; then
        icon_font="$MONO_FONT:Regular:$FONT_SIZE"
        icon_color=$WS_FOCUSED
        icon_state="focused"
    else
        icon_font="$MONO_FONT:Regular:$FONT_SIZE"
        icon_color=$WS_UNFOCUSED
        icon_state="unfocused"
    fi

    # Width-based grid: all gaps baked into width, padding only for text offset
    if [[ "$ws" == "$m1_ws" ]]; then
        # M1 active (mirrored): shift text left toward icons
        letter_icon_pad=$M1_TEXT_SHIFT
        letter_width=$CELL
    elif [[ "$ws" == "$m2_ws" ]]; then
        # M2 active (normal): text left-aligned, near divider
        letter_icon_pad=0
        letter_width=$CELL
    else
        letter_icon_pad=$WORKSPACE_GAP
        letter_width=$((CELL + WORKSPACE_GAP))
    fi

    if [[ $num_apps -eq 0 && "$ws" != "$focused_ws" && "$ws" != "$m1_ws" && "$ws" != "$m2_ws" ]]; then
        BATCH_CMD="$BATCH_CMD --set space.$ws icon.drawing=off icon.padding_left=0 icon.padding_right=0 padding_left=0 padding_right=0 width=0"
    else
        BATCH_CMD="$BATCH_CMD --set space.$ws icon='${icon_prefix}${ws}${icon_suffix}' icon.drawing=on icon.font='$icon_font' icon.color=$icon_color icon.padding_left=$letter_icon_pad icon.padding_right=0 padding_left=0 padding_right=0 width=$letter_width"
    fi

    for i in 0 1 2 3; do
        item_name="space.$ws.icon.$i"
        if [[ $i -lt $num_apps ]]; then
            bundle="${BUNDLES[$i]}"
            icon_w=$CELL
            if [[ "$ws" == "$m1_ws" && $num_apps -eq $MAX_ICONS && $i -eq $((MAX_ICONS - 1)) ]]; then
                icon_w=$((CELL + WORKSPACE_GAP))
            fi
            custom_icon=$(get_custom_icon_dimmed "$bundle" "$icon_state")
            if [[ -n "$custom_icon" && -f "$custom_icon" ]]; then
                BATCH_CMD="$BATCH_CMD --set $item_name icon.drawing=off background.image='$custom_icon' background.image.scale=$ICON_SCALE background.image.drawing=on width=$icon_w padding_left=0 padding_right=0 click_script='open -b $bundle'"
            else
                BATCH_CMD="$BATCH_CMD --set $item_name icon.drawing=off background.image='app.$bundle' background.image.scale=$ICON_SCALE background.image.drawing=on width=$icon_w padding_left=0 padding_right=0 click_script='open -b $bundle'"
            fi
        else
            if [[ "$ws" == "$m1_ws" && $i -eq $((MAX_ICONS - 1)) ]]; then
                BATCH_CMD="$BATCH_CMD --set $item_name icon.drawing=off background.image.drawing=off width=$WORKSPACE_GAP padding_left=0 padding_right=0"
            else
                BATCH_CMD="$BATCH_CMD --set $item_name icon.drawing=off background.image.drawing=off width=0 padding_left=0 padding_right=0"
            fi
        fi
    done
done

echo "$focused_ws $m1_ws $m2_ws" > "$PREV_STATE"
eval "$BATCH_CMD"

# === Reorder: all non-active [letter][icons], M1 mirrored [icons][letter] ===
REORDER=""
for ws in Q W E R T A S D F G Z X C V B; do
    [[ "$ws" == "$m1_ws" || "$ws" == "$m2_ws" ]] && continue
    REORDER="$REORDER space.$ws space.$ws.icon.0 space.$ws.icon.1 space.$ws.icon.2 space.$ws.icon.3"
done
if [[ -n "$m1_ws" ]]; then
    REORDER="$REORDER space.$m1_ws.icon.3 space.$m1_ws.icon.2 space.$m1_ws.icon.1 space.$m1_ws.icon.0 space.$m1_ws"
fi
REORDER="$REORDER space_div"
if [[ -n "$m2_ws" && "$m2_ws" != "$m1_ws" ]]; then
    REORDER="$REORDER space.$m2_ws space.$m2_ws.icon.0 space.$m2_ws.icon.1 space.$m2_ws.icon.2 space.$m2_ws.icon.3"
fi
for ws in Y U I O P H J K L N M; do
    [[ "$ws" == "$m1_ws" || "$ws" == "$m2_ws" ]] && continue
    REORDER="$REORDER space.$ws space.$ws.icon.0 space.$ws.icon.1 space.$ws.icon.2 space.$ws.icon.3"
done
REORDER="$REORDER space_balance"
sketchybar --reorder $REORDER
