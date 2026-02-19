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
ICON_SCALE=0.5
CELL=6
ICON_W=12
WS_GAP=6
DIVIDER_WIDTH=12
MONO_FONT="Iosevka Extended"
WORKSPACES="Q W E R T Y U I O P A S D F G H J K L Z X C V B N M"
LEFT_KEYS=" Q W E R T A S D F G Z X C V B "

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

    # All letter cells = CELL (6px). Arrows are separate items.
    letter_width=$CELL

    is_active=0
    [[ "$ws" == "$m1_ws" || "$ws" == "$m2_ws" ]] && is_active=1

    if [[ $num_apps -eq 0 && "$ws" != "$focused_ws" && $is_active -eq 0 ]]; then
        BATCH_CMD="$BATCH_CMD --set space.$ws icon.drawing=off width=0"
        BATCH_CMD="$BATCH_CMD --set space.$ws.gr width=0"
        BATCH_CMD="$BATCH_CMD --set space.$ws.gl width=0"
    else
        # Gap right (before letter)
        if [[ $is_active -eq 0 ]]; then
            BATCH_CMD="$BATCH_CMD --set space.$ws.gr width=$WS_GAP"
        else
            BATCH_CMD="$BATCH_CMD --set space.$ws.gr width=0"
        fi

        BATCH_CMD="$BATCH_CMD --set space.$ws icon='$ws' icon.drawing=on icon.font='$icon_font' icon.color=$icon_color icon.align=center icon.padding_left=0 icon.padding_right=0 padding_left=0 padding_right=0 width=$letter_width"
    fi

    # Icon slots
    for i in 0 1 2 3; do
        item_name="space.$ws.icon.$i"
        if [[ $i -lt $num_apps ]]; then
            bundle="${BUNDLES[$i]}"
            icon_w=$ICON_W
            custom_icon=$(get_custom_icon_dimmed "$bundle" "$icon_state")
            if [[ -n "$custom_icon" && -f "$custom_icon" ]]; then
                BATCH_CMD="$BATCH_CMD --set $item_name icon.drawing=off background.image='$custom_icon' background.image.scale=$ICON_SCALE background.image.drawing=on width=$icon_w padding_left=0 padding_right=0 click_script='open -b $bundle'"
            else
                BATCH_CMD="$BATCH_CMD --set $item_name icon.drawing=off background.image='app.$bundle' background.image.scale=$ICON_SCALE background.image.drawing=on width=$icon_w padding_left=0 padding_right=0 click_script='open -b $bundle'"
            fi
        else
            BATCH_CMD="$BATCH_CMD --set $item_name icon.drawing=off background.image.drawing=off width=0 padding_left=0 padding_right=0"
        fi
    done

    # Gap left (after icons)
    if [[ $num_apps -gt 0 || "$ws" == "$focused_ws" || $is_active -eq 1 ]]; then
        if [[ $is_active -eq 0 ]]; then
            BATCH_CMD="$BATCH_CMD --set space.$ws.gl width=$WS_GAP"
        else
            BATCH_CMD="$BATCH_CMD --set space.$ws.gl width=0"
        fi
    fi
done

# === Balance: recalculate for new left/right distribution ===
# Must scan ALL workspaces since monitors may have changed.
w_left=0
w_right=0
first_left="" last_left="" first_right="" last_right=""
for ws in $WORKSPACES; do
    local_bundles=$(get_cached_workspace_apps "$ws")
    IFS=' ' read -ra WS_BUNDLES <<< "$local_bundles"
    ws_apps=${#WS_BUNDLES[@]}

    ws_w=0
    ws_active=0
    [[ "$ws" == "$m1_ws" || "$ws" == "$m2_ws" ]] && ws_active=1
    if [[ $ws_apps -eq 0 && "$ws" != "$focused_ws" && $ws_active -eq 0 ]]; then
        ws_w=0
    else
        [[ $ws_active -eq 0 ]] && ws_w=$((WS_GAP * 2))
        ws_w=$((ws_w + CELL))
        for i in 0 1 2 3; do
            [[ $i -lt $ws_apps ]] && ws_w=$((ws_w + ICON_W))
        done
    fi

    # Track first/last visible non-active per side
    if [[ $ws_w -gt 0 && $ws_active -eq 0 ]]; then
        if [[ $LEFT_KEYS == *" $ws "* ]]; then
            [[ -z "$first_left" ]] && first_left="$ws"
            last_left="$ws"
        else
            [[ -z "$first_right" ]] && first_right="$ws"
            last_right="$ws"
        fi
    fi

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

# Zero outer-edge gaps only
[[ -n "$first_left" ]] && BATCH_CMD="$BATCH_CMD --set space.$first_left.gr width=0" && w_left=$((w_left - WS_GAP))
[[ -n "$last_right" ]] && BATCH_CMD="$BATCH_CMD --set space.$last_right.gl width=0" && w_right=$((w_right - WS_GAP))
# Double gaps adjacent to active
[[ -n "$last_left" ]] && BATCH_CMD="$BATCH_CMD --set space.$last_left.gl width=$((WS_GAP * 2))" && w_left=$((w_left + WS_GAP))
[[ -n "$first_right" ]] && BATCH_CMD="$BATCH_CMD --set space.$first_right.gr width=$((WS_GAP * 2))" && w_right=$((w_right + WS_GAP))

# Arrow items — separate 6px cells for ◂/▸
if [[ -n "$m1_ws" ]]; then
    BATCH_CMD="$BATCH_CMD --set space_arrow_m1 icon.drawing=on icon.color=$WS_FOCUSED width=$CELL"
    w_left=$((w_left + CELL))
else
    BATCH_CMD="$BATCH_CMD --set space_arrow_m1 icon.drawing=off width=0"
fi
if [[ -n "$m2_ws" && "$m2_ws" != "$m1_ws" ]]; then
    BATCH_CMD="$BATCH_CMD --set space_arrow_m2 icon.drawing=on icon.color=$WS_FOCUSED width=$CELL"
    w_right=$((w_right + CELL))
else
    BATCH_CMD="$BATCH_CMD --set space_arrow_m2 icon.drawing=off width=0"
fi

algebraic_raw=$((w_left - w_right))
balance_raw=$algebraic_raw

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
    REORDER="$REORDER space.$ws.gr space.$ws space.$ws.icon.0 space.$ws.icon.1 space.$ws.icon.2 space.$ws.icon.3 space.$ws.gl"
done
if [[ -n "$m1_ws" ]]; then
    REORDER="$REORDER space.$m1_ws.gr space.$m1_ws.icon.3 space.$m1_ws.icon.2 space.$m1_ws.icon.1 space.$m1_ws.icon.0 space.$m1_ws space_arrow_m1 space.$m1_ws.gl"
fi
REORDER="$REORDER space_div"
if [[ -n "$m2_ws" && "$m2_ws" != "$m1_ws" ]]; then
    REORDER="$REORDER space.$m2_ws.gr space_arrow_m2 space.$m2_ws space.$m2_ws.icon.0 space.$m2_ws.icon.1 space.$m2_ws.icon.2 space.$m2_ws.icon.3 space.$m2_ws.gl"
fi
for ws in Y U I O P H J K L N M; do
    [[ "$ws" == "$m1_ws" || "$ws" == "$m2_ws" ]] && continue
    REORDER="$REORDER space.$ws.gr space.$ws space.$ws.icon.0 space.$ws.icon.1 space.$ws.icon.2 space.$ws.icon.3 space.$ws.gl"
done
[[ "$balance_side" == "right" ]] && REORDER="$REORDER space_balance"
sketchybar --reorder $REORDER
