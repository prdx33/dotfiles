#!/bin/zsh
# Toggle single window float/tile
# - Float: center-half via Rectangle
# - Tile: joins existing tree, balanced

AEROSPACE="/opt/homebrew/bin/aerospace"

layout=$($AEROSPACE list-windows --focused --format "%{window-layout}")

if [[ "$layout" == "floating" ]]; then
    # Floating → Tiling
    $AEROSPACE layout tiling
    $AEROSPACE balance-sizes
else
    # Tiling → Floating: center-half
    $AEROSPACE layout floating
    open -g "rectangle://execute-action?name=center-half"
fi
