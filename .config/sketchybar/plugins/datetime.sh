#!/bin/bash

# Date/Time plugin - updates both stacked items
# Date: SA 2501 (day abbrev + DDMM)
# Time: 5:34 PM

day_abbrev=$(date '+%a' | cut -c1-2 | tr '[:lower:]' '[:upper:]')
date_fmt=$(date '+%d%m')
time=$(date '+%l:%M %p' | tr '[:lower:]' '[:upper:]')

sketchybar --set date label=" ${day_abbrev} ${date_fmt}" \
           --set time label="${time}"
