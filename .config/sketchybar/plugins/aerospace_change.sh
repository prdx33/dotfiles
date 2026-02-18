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
DIVIDER_WIDTH=12
ACTIVE_NARROW=6
DIVIDER_WIDTH=1
MONO_FONT="Iosevka Extended"
WORKSPACES="Q W E R T Y U I O P A S D F G H J K L Z X C V B N M"
LEFT_KEYS=" Q W E R T A S D F G Z X C V B "
BALANCE_CACHE="/tmp/sketchybar_balance_cache"

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

    # Width-based grid: all gaps baked into width
    # Active letters: widened by ACTIVE_NARROW (taken from icon.0), text toward icon
    if [[ "$ws" == "$m1_ws" || "$ws" == "$m2_ws" ]]; then
        letter_icon_pad=0
        letter_align="center"
        letter_width=$((CELL + ACTIVE_NARROW))
    else
        letter_icon_pad=$WORKSPACE_GAP
        letter_align="left"
        letter_width=$((CELL + WORKSPACE_GAP))
    fi

    if [[ $num_apps -eq 0 && "$ws" != "$focused_ws" && "$ws" != "$m1_ws" && "$ws" != "$m2_ws" ]]; then
        BATCH_CMD="$BATCH_CMD --set space.$ws icon.drawing=off icon.padding_left=0 icon.padding_right=0 padding_left=0 padding_right=0 width=0"
    else
        BATCH_CMD="$BATCH_CMD --set space.$ws icon='${icon_prefix}${ws}${icon_suffix}' icon.drawing=on icon.font='$icon_font' icon.color=$icon_color icon.align=$letter_align icon.padding_left=$letter_icon_pad icon.padding_right=0 padding_left=0 padding_right=0 width=$letter_width"
    fi

    for i in 0 1 2 3; do
        item_name="space.$ws.icon.$i"
        if [[ $i -lt $num_apps ]]; then
            bundle="${BUNDLES[$i]}"
            icon_w=$CELL
            if [[ $i -eq 0 && ("$ws" == "$m1_ws" || "$ws" == "$m2_ws") ]]; then
                icon_w=$((CELL - ACTIVE_NARROW))
            fi
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

# === Balance: recalculate for new left/right distribution ===
# Must scan ALL workspaces since monitors may have changed.
w_left=0
w_right=0
for ws in $WORKSPACES; do
    local_bundles=$(get_cached_workspace_apps "$ws")
    IFS=' ' read -ra WS_BUNDLES <<< "$local_bundles"
    ws_apps=${#WS_BUNDLES[@]}

    # Calculate this workspace's total width
    ws_w=0
    if [[ $ws_apps -eq 0 && "$ws" != "$focused_ws" && "$ws" != "$m1_ws" && "$ws" != "$m2_ws" ]]; then
        ws_w=0  # hidden
    else
        # Letter width
        if [[ "$ws" == "$m1_ws" || "$ws" == "$m2_ws" ]]; then
            ws_w=$((CELL + ACTIVE_NARROW))
        else
            ws_w=$((CELL + WORKSPACE_GAP))
        fi
        # Icon widths
        for i in 0 1 2 3; do
            if [[ $i -lt $ws_apps ]]; then
                if [[ $i -eq 0 && ("$ws" == "$m1_ws" || "$ws" == "$m2_ws") ]]; then
                    ws_w=$((ws_w + CELL - ACTIVE_NARROW))
                elif [[ "$ws" == "$m1_ws" && $ws_apps -eq $MAX_ICONS && $i -eq $((MAX_ICONS - 1)) ]]; then
                    ws_w=$((ws_w + CELL + WORKSPACE_GAP))
                else
                    ws_w=$((ws_w + CELL))
                fi
            elif [[ "$ws" == "$m1_ws" && $i -eq $((MAX_ICONS - 1)) ]]; then
                ws_w=$((ws_w + WORKSPACE_GAP))
            fi
        done
    fi

    # Accumulate to correct side
    if [[ "$ws" == "$m1_ws" ]]; then
        w_left=$((w_left + ws_w))
    elif [[ "$ws" == "$m2_ws" ]]; then
        w_right=$((w_right + ws_w))
    elif [[ $LEFT_KEYS == *" $ws "* ]]; then
        w_left=$((w_left + ws_w))
    else
        w_right=$((w_right + ws_w))
    fi
done

algebraic_raw=$((w_left - w_right))
cached_correction=$(cat "$BALANCE_CACHE" 2>/dev/null)
[[ -z "$cached_correction" || ! "$cached_correction" =~ ^-?[0-9]+$ ]] && cached_correction=0
balance_raw=$((algebraic_raw + cached_correction))

if [[ $balance_raw -ge 0 ]]; then
    balance=$balance_raw
    balance_side="right"
else
    balance=$(( -balance_raw ))
    balance_side="left"
fi
BATCH_CMD="$BATCH_CMD --set space_balance width=$balance"

echo "$focused_ws $m1_ws $m2_ws" > "$PREV_STATE"
eval "$BATCH_CMD"

# === Reorder: all non-active [letter][icons], M1 mirrored [icons][letter] ===
# Balance spacer placed on the shorter side.
REORDER=""
[[ "$balance_side" == "left" ]] && REORDER="$REORDER space_balance"
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
[[ "$balance_side" == "right" ]] && REORDER="$REORDER space_balance"
sketchybar --reorder $REORDER
