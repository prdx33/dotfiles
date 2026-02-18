#!/bin/bash

# Date/Time plugin - updates both stacked items
# Date: SAT 1802 (day abbrev + DDMM) — white, except SUN turns muted red
# Time: 5:34 PM

source "$CONFIG_DIR/colours.sh" 2>/dev/null || exit 0

day_abbrev=$(date '+%a' | cut -c1-3 | tr '[:lower:]' '[:upper:]')
date_fmt=$(date '+%d%m')
time=$(date '+%I:%M%p' | tr '[:lower:]' '[:upper:]')

# Sunday gets muted red accent, all other days white
if [[ "$day_abbrev" == "SUN" ]]; then
    date_color=$STAT_DATE_SUN
else
    date_color=$LABEL_COLOR
fi

# Respect idle fade
if [[ -f /tmp/sketchybar_bar_faded ]]; then
    sketchybar --set date label="${day_abbrev}${date_fmt}" label.color=$DIM_IDLE \
               --set time label="${time}" label.color=$DIM_IDLE
else
    sketchybar --set date label="${day_abbrev}${date_fmt}" label.color="$date_color" \
               --set time label="${time}"
fi
