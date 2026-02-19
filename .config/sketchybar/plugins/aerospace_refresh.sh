#!/bin/bash

# Refresh all workspace items (batched for performance)
# Split layout: left-hand ws (mirrored) | divider | right-hand ws (normal)
# All center-positioned. Balance spacer pins divider to bar midpoint.

# Exclusive lock — only one instance runs at a time
LOCKDIR="/tmp/aerospace_refresh.lock"
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

CONFIG_DIR="$HOME/.config/sketchybar"
source "$CONFIG_DIR/colours.sh" 2>/dev/null || exit 0
source "$CONFIG_DIR/plugins/app_icons.sh" 2>/dev/null

# === Grid model ===
# CRITICAL: padding does NOT affect center layout flow — only width does.
# All inter-group gaps are baked into item widths.
# icon.padding_left offsets text rendering within cells (doesn't affect flow).
#
# Layout: [unfocused LHS] [M1 mirrored] |div| [M2 normal] [unfocused RHS]
# Non-active: [letter(+gap)][icons] — WORKSPACE_GAP baked into letter width
# M1 active:  [spacer][icons][◂letter] |div| — icon.3 spacer or widened first icon
# M2 active:  |div| [letter▸][icons]

MAX_ICONS=4
FONT_SIZE=10.0
ICON_SCALE=0.5
CELL=6              # letter width (matches glyph advance at 10pt)
ICON_W=12           # icon cell width (24px * 0.5 scale)
WS_GAP=6            # gap_right (before letter) + gap_left (after icons) for non-active
DIVIDER_WIDTH=12    # breathing room between M1 and M2 active letters
MONO_FONT="Iosevka Extended"

WORKSPACES="Q W E R T Y U I O P A S D F G H J K L Z X C V B N M"

# Get visible workspace for each monitor
m1_ws=$(aerospace list-workspaces --monitor 1 --visible 2>/dev/null | xargs)
m2_ws=$(aerospace list-workspaces --monitor 2 --visible 2>/dev/null | xargs)
focused_ws=$(aerospace list-workspaces --focused 2>/dev/null | xargs)

# Single aerospace query for all window data
cache_all_workspace_apps

# Keyboard side classification for balance calculation
LEFT_KEYS=" Q W E R T A S D F G Z X C V B "

# Build batched sketchybar command
BATCH_CMD="sketchybar"
w_left=0   # total width of items left of divider
w_right=0  # total width of items right of divider (excluding balance spacer)
first_left="" last_left="" first_right="" last_right=""

for space_id in $WORKSPACES; do
    bundle_ids=$(get_cached_workspace_apps "$space_id")
    IFS=' ' read -ra BUNDLES <<< "$bundle_ids"
    num_apps=${#BUNDLES[@]}

    # Determine visual state
    if [[ "$space_id" == "$focused_ws" ]]; then
        icon_font="$MONO_FONT:Heavy:$FONT_SIZE"
        icon_color=$WS_FOCUSED
        icon_state="focused"
    elif [[ "$space_id" == "$m1_ws" || "$space_id" == "$m2_ws" ]]; then
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

    # Hide if empty and not visible on any monitor
    group_w=0
    is_active=0
    [[ "$space_id" == "$m1_ws" || "$space_id" == "$m2_ws" ]] && is_active=1

    if [[ $num_apps -eq 0 && "$space_id" != "$focused_ws" && $is_active -eq 0 ]]; then
        # Hidden workspace — zero everything
        BATCH_CMD="$BATCH_CMD --set space.$space_id icon.drawing=off width=0"
        BATCH_CMD="$BATCH_CMD --set space.$space_id.gr width=0"
        BATCH_CMD="$BATCH_CMD --set space.$space_id.gl width=0"
    else
        # Gap right (before letter) — 6px for non-active, 0 for active
        if [[ $is_active -eq 0 ]]; then
            BATCH_CMD="$BATCH_CMD --set space.$space_id.gr width=$WS_GAP"
            group_w=$WS_GAP
        else
            BATCH_CMD="$BATCH_CMD --set space.$space_id.gr width=0"
        fi

        # Letter
        BATCH_CMD="$BATCH_CMD --set space.$space_id icon='$space_id' icon.drawing=on icon.font='$icon_font' icon.color=$icon_color icon.align=center icon.padding_left=0 icon.padding_right=0 padding_left=0 padding_right=0 width=$letter_width"
        group_w=$((group_w + letter_width))
    fi

    # Icon slots
    for i in 0 1 2 3; do
        item_name="space.$space_id.icon.$i"
        if [[ $i -lt $num_apps ]]; then
            bundle="${BUNDLES[$i]}"
            icon_w=$ICON_W
            custom_icon=$(get_custom_icon_dimmed "$bundle" "$icon_state")
            if [[ -n "$custom_icon" && -f "$custom_icon" ]]; then
                BATCH_CMD="$BATCH_CMD --set $item_name icon.drawing=off background.image='$custom_icon' background.image.scale=$ICON_SCALE background.image.drawing=on width=$icon_w padding_left=0 padding_right=0 click_script='open -b $bundle'"
            else
                BATCH_CMD="$BATCH_CMD --set $item_name icon.drawing=off background.image='app.$bundle' background.image.scale=$ICON_SCALE background.image.drawing=on width=$icon_w padding_left=0 padding_right=0 click_script='open -b $bundle'"
            fi
            group_w=$((group_w + icon_w))
        else
            BATCH_CMD="$BATCH_CMD --set $item_name icon.drawing=off background.image.drawing=off width=0 padding_left=0 padding_right=0"
        fi
    done

    # Gap left (after icons) — 6px for non-active visible, 0 for active/hidden
    if [[ $num_apps -gt 0 || "$space_id" == "$focused_ws" || $is_active -eq 1 ]]; then
        if [[ $is_active -eq 0 ]]; then
            BATCH_CMD="$BATCH_CMD --set space.$space_id.gl width=$WS_GAP"
            group_w=$((group_w + WS_GAP))
        else
            BATCH_CMD="$BATCH_CMD --set space.$space_id.gl width=0"
        fi
    fi

    # Accumulate width to correct side + track first/last visible non-active per side
    if [[ $group_w -gt 0 && $is_active -eq 0 ]]; then
        if [[ $LEFT_KEYS == *" $space_id "* ]]; then
            [[ -z "$first_left" ]] && first_left="$space_id"
            last_left="$space_id"
        else
            [[ -z "$first_right" ]] && first_right="$space_id"
            last_right="$space_id"
        fi
    fi
    if [[ "$space_id" == "$m1_ws" ]]; then
        w_left=$((w_left + group_w))
    elif [[ "$space_id" == "$m2_ws" ]]; then
        w_right=$((w_right + group_w))
    elif [[ $LEFT_KEYS == *" $space_id "* ]]; then
        w_left=$((w_left + group_w))
    else
        w_right=$((w_right + group_w))
    fi
done

# Zero outer-edge gaps only
[[ -n "$first_left" ]] && BATCH_CMD="$BATCH_CMD --set space.$first_left.gr width=0" && w_left=$((w_left - WS_GAP))
[[ -n "$last_right" ]] && BATCH_CMD="$BATCH_CMD --set space.$last_right.gl width=0" && w_right=$((w_right - WS_GAP))
# Double gaps adjacent to active (compensate for active having no gaps)
[[ -n "$last_left" ]] && BATCH_CMD="$BATCH_CMD --set space.$last_left.gl width=$((WS_GAP * 2))" && w_left=$((w_left + WS_GAP))
[[ -n "$first_right" ]] && BATCH_CMD="$BATCH_CMD --set space.$first_right.gr width=$((WS_GAP * 2))" && w_right=$((w_right + WS_GAP))

# Balance spacer: compensates for left/right width asymmetry so divider stays centred.

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

# Recalculate balance with arrow widths included
algebraic_raw=$((w_left - w_right))
balance_raw=$algebraic_raw

if [[ $balance_raw -ge 0 ]]; then
    balance=$balance_raw
    balance_side="right"
else
    balance=$(( -balance_raw ))
    balance_side="left"
fi

BATCH_CMD="$BATCH_CMD --set space_div width=$DIVIDER_WIDTH --set space_balance width=$balance"

eval "$BATCH_CMD"

# === Reorder ===
# All non-active: normal [letter][icons]. Only M1 active is mirrored [icons][letter].
# Balance spacer goes on the shorter side (left or right of divider).
REORDER=""

# Balance spacer on left if right side is heavier
[[ "$balance_side" == "left" ]] && REORDER="$REORDER space_balance"

# Left-hand non-active workspaces: [gr][letter][icons][gl]
for ws in Q W E R T A S D F G Z X C V B; do
    [[ "$ws" == "$m1_ws" || "$ws" == "$m2_ws" ]] && continue
    REORDER="$REORDER space.$ws.gr space.$ws space.$ws.icon.0 space.$ws.icon.1 space.$ws.icon.2 space.$ws.icon.3 space.$ws.gl"
done

# M1 active (mirrored: icons then letter then arrow flush to divider — no gaps)
if [[ -n "$m1_ws" ]]; then
    REORDER="$REORDER space.$m1_ws.gr space.$m1_ws.icon.3 space.$m1_ws.icon.2 space.$m1_ws.icon.1 space.$m1_ws.icon.0 space.$m1_ws space_arrow_m1 space.$m1_ws.gl"
fi

REORDER="$REORDER space_div"

# M2 active (arrow then letter then icons — no gaps)
if [[ -n "$m2_ws" && "$m2_ws" != "$m1_ws" ]]; then
    REORDER="$REORDER space.$m2_ws.gr space_arrow_m2 space.$m2_ws space.$m2_ws.icon.0 space.$m2_ws.icon.1 space.$m2_ws.icon.2 space.$m2_ws.icon.3 space.$m2_ws.gl"
fi

# Right-hand non-active workspaces: [gr][letter][icons][gl]
for ws in Y U I O P H J K L N M; do
    [[ "$ws" == "$m1_ws" || "$ws" == "$m2_ws" ]] && continue
    REORDER="$REORDER space.$ws.gr space.$ws space.$ws.icon.0 space.$ws.icon.1 space.$ws.icon.2 space.$ws.icon.3 space.$ws.gl"
done

# Balance spacer on right if left side is heavier
[[ "$balance_side" == "right" ]] && REORDER="$REORDER space_balance"

sketchybar --reorder $REORDER

