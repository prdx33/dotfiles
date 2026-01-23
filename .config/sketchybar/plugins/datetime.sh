#!/bin/bash

# Date/Time plugin - format: FRI 23 JAN 2:34 PM (ALL CAPS, spaced)

day=$(date '+%a' | tr '[:lower:]' '[:upper:]')
date_num=$(date '+%d')
month=$(date '+%b' | tr '[:lower:]' '[:upper:]')
time=$(date '+%l:%M %p' | tr '[:lower:]' '[:upper:]' | xargs)

sketchybar --set $NAME label="${day} ${date_num} ${month} ${time}"
