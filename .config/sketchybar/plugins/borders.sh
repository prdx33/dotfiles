#!/bin/bash

# JankyBorders dynamic colour update
# Called on focus change to set border colour based on window layout
# - Floating: white (0xffFAFAFA)
# - Tiled: pastel orange (0xffFFB380)

FLOATING_COLOR="0xffFAFAFA"
TILED_COLOR="0xffFFB380"

# Get focused window layout
layout=$(aerospace list-windows --focused --format '%{window-layout}' 2>/dev/null)

if [[ "$layout" == "floating" ]]; then
    borders active_color=$FLOATING_COLOR
else
    # Any tiled layout (tiles, h_tiles, v_tiles, accordion, etc.)
    borders active_color=$TILED_COLOR
fi
