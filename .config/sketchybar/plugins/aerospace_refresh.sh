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
ICON_SCALE=0.38
CELL=20             # uniform grid cell width
WORKSPACE_GAP=20    # gap between workspace groups (= 1 cell)
M1_TEXT_SHIFT=-10   # shifts M1 letter text toward its icons (negative = left)
DIVIDER_WIDTH=1     # visual divider between M1 and M2
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

for space_id in $WORKSPACES; do
    bundle_ids=$(get_cached_workspace_apps "$space_id")
    IFS=' ' read -ra BUNDLES <<< "$bundle_ids"
    num_apps=${#BUNDLES[@]}

    # Monitor indicators — arrows point outward from centre
    icon_prefix=""
    icon_suffix=""
    [[ "$space_id" == "$m1_ws" ]] && icon_prefix="◂"
    [[ "$space_id" == "$m2_ws" ]] && icon_suffix="▸"

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

    # Width-based grid: all gaps baked into width, padding only for text offset
    # Active letters: icon.padding_left shifts text rendering without affecting layout
    if [[ "$space_id" == "$m1_ws" ]]; then
        # M1 active (mirrored): shift text left toward icons, away from divider
        letter_icon_pad=$M1_TEXT_SHIFT
        letter_width=$CELL
    elif [[ "$space_id" == "$m2_ws" ]]; then
        # M2 active (normal): text left-aligned, naturally near divider
        letter_icon_pad=0
        letter_width=$CELL
    else
        # Non-active: gap baked into width, icon.padding_left pushes text right
        letter_icon_pad=$WORKSPACE_GAP
        letter_width=$((CELL + WORKSPACE_GAP))
    fi

    # Hide if empty and not visible on any monitor
    group_w=0  # track total width for this workspace group
    if [[ $num_apps -eq 0 && "$space_id" != "$focused_ws" && "$space_id" != "$m1_ws" && "$space_id" != "$m2_ws" ]]; then
        BATCH_CMD="$BATCH_CMD --set space.$space_id icon.drawing=off icon.padding_left=0 icon.padding_right=0 padding_left=0 padding_right=0 width=0"
    else
        BATCH_CMD="$BATCH_CMD --set space.$space_id icon='${icon_prefix}${space_id}${icon_suffix}' icon.drawing=on icon.font='$icon_font' icon.color=$icon_color icon.padding_left=$letter_icon_pad icon.padding_right=0 padding_left=0 padding_right=0 width=$letter_width"
        group_w=$letter_width
    fi

    # Update icon slots
    for i in 0 1 2 3; do
        item_name="space.$space_id.icon.$i"
        if [[ $i -lt $num_apps ]]; then
            bundle="${BUNDLES[$i]}"
            # M1 mirrored: outermost occupied icon absorbs WORKSPACE_GAP
            # When all MAX_ICONS slots full: icon.3 (first visual) = CELL + GAP
            # When fewer apps: empty icon.3 becomes spacer (handled below)
            icon_w=$CELL
            if [[ "$space_id" == "$m1_ws" && $num_apps -eq $MAX_ICONS && $i -eq $((MAX_ICONS - 1)) ]]; then
                icon_w=$((CELL + WORKSPACE_GAP))
            fi
            custom_icon=$(get_custom_icon_dimmed "$bundle" "$icon_state")
            if [[ -n "$custom_icon" && -f "$custom_icon" ]]; then
                BATCH_CMD="$BATCH_CMD --set $item_name icon.drawing=off background.image='$custom_icon' background.image.scale=$ICON_SCALE background.image.drawing=on width=$icon_w padding_left=0 padding_right=0 click_script='open -b $bundle'"
            else
                BATCH_CMD="$BATCH_CMD --set $item_name icon.drawing=off background.image='app.$bundle' background.image.scale=$ICON_SCALE background.image.drawing=on width=$icon_w padding_left=0 padding_right=0 click_script='open -b $bundle'"
            fi
            group_w=$((group_w + icon_w))
        else
            # Empty icon slot — M1's icon.3 becomes spacer for group gap
            if [[ "$space_id" == "$m1_ws" && $i -eq $((MAX_ICONS - 1)) ]]; then
                BATCH_CMD="$BATCH_CMD --set $item_name icon.drawing=off background.image.drawing=off width=$WORKSPACE_GAP padding_left=0 padding_right=0"
                group_w=$((group_w + WORKSPACE_GAP))
            else
                BATCH_CMD="$BATCH_CMD --set $item_name icon.drawing=off background.image.drawing=off width=0 padding_left=0 padding_right=0"
            fi
        fi
    done

    # Accumulate width to correct side for balance calculation
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

# Balance spacer: compensates for left/right width asymmetry so divider stays centred.
# Two-phase: algebraic gives workspace asymmetry, cached correction adds bar-section offset.
# Cache file stores the fine-tune correction from the last run for instant application.
BALANCE_CACHE="/tmp/sketchybar_balance_cache"
algebraic=$((w_left - w_right))
[[ $algebraic -lt 0 ]] && algebraic=0
balance=$algebraic
cached_correction=$(cat "$BALANCE_CACHE" 2>/dev/null)
if [[ -n "$cached_correction" && "$cached_correction" =~ ^-?[0-9]+$ ]]; then
    balance=$((algebraic + cached_correction))
    [[ $balance -lt 0 ]] && balance=0
fi

BATCH_CMD="$BATCH_CMD --set space_div width=$DIVIDER_WIDTH --set space_balance width=$balance"

eval "$BATCH_CMD"

# === Reorder ===
# All non-active: normal [letter][icons]. Only M1 active is mirrored [icons][letter].
REORDER=""

# Left-hand non-active workspaces (normal: letter then icons)
for ws in Q W E R T A S D F G Z X C V B; do
    [[ "$ws" == "$m1_ws" || "$ws" == "$m2_ws" ]] && continue
    REORDER="$REORDER space.$ws space.$ws.icon.0 space.$ws.icon.1 space.$ws.icon.2 space.$ws.icon.3"
done

# M1 active (mirrored: icons then letter — icons outer, letter flush to divider)
if [[ -n "$m1_ws" ]]; then
    REORDER="$REORDER space.$m1_ws.icon.3 space.$m1_ws.icon.2 space.$m1_ws.icon.1 space.$m1_ws.icon.0 space.$m1_ws"
fi

REORDER="$REORDER space_div"

# M2 active (normal: letter then icons — letter flush to divider, icons outer)
if [[ -n "$m2_ws" && "$m2_ws" != "$m1_ws" ]]; then
    REORDER="$REORDER space.$m2_ws space.$m2_ws.icon.0 space.$m2_ws.icon.1 space.$m2_ws.icon.2 space.$m2_ws.icon.3"
fi

# Right-hand non-active workspaces (normal: letter then icons)
for ws in Y U I O P H J K L N M; do
    [[ "$ws" == "$m1_ws" || "$ws" == "$m2_ws" ]] && continue
    REORDER="$REORDER space.$ws space.$ws.icon.0 space.$ws.icon.1 space.$ws.icon.2 space.$ws.icon.3"
done

REORDER="$REORDER space_balance"

sketchybar --reorder $REORDER

# === Fine-tune balance — accounts for asymmetric left/right bar sections ===
# Only needed when cache is empty (cold start) or stale. With a valid cache,
# the algebraic + cached correction is already accurate to ±1px.
if [[ -z "$cached_correction" || ! "$cached_correction" =~ ^-?[0-9]+$ ]]; then
    sleep 0.5  # cold start: wait for layout to settle
    finetune=$(python3 -c "
import subprocess, json
def q(item):
    r = subprocess.run(['sketchybar', '--query', item], capture_output=True, text=True)
    return json.loads(r.stdout).get('bounding_rects',{}).get('display-1') if r.stdout.strip() else None
div, lft, rgt, bal = q('space_div'), q('app_icon'), q('date'), q('space_balance')
if div and lft and rgt and bal:
    bar_center = (lft['origin'][0] + rgt['origin'][0] + rgt['size'][0]) / 2
    div_center = div['origin'][0] + div['size'][0] / 2
    cur = int(bal['size'][0])
    delta = int(2 * (div_center - bar_center))
    print(max(0, cur + delta))
else:
    print(-1)
" 2>/dev/null)
    if [[ "$finetune" -ge 0 ]] 2>/dev/null; then
        sketchybar --set space_balance width=$finetune
        echo "$((finetune - algebraic))" > "$BALANCE_CACHE"
    fi
fi
