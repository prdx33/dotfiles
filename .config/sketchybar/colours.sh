#!/bin/bash

# Font - monospace
export FONT="Iosevka Extended"
export MONO_FONT="Iosevka Extended"

# Bar
export BAR_COLOR=0x80000000

# Text
export LABEL_COLOR=0xccffffff
export STAT_LABEL=0xccffffff

# Bathory stat labels - orange: saturated→pale, green: U/D light, R/W dark
export STAT_NET_UP=0xff90b898       # U - light sage (lighter)
export STAT_NET_DOWN=0xff80a888     # D - light sage (darker)
export STAT_DISK_READ=0xffb0a888    # R - olive taupe (lighter)
export STAT_DISK_WRITE=0xff909078   # W - khaki brown (darker)
export STAT_MEM=0xffd8b890          # MEM - pale cream (lightest orange)
export STAT_GPU=0xffc8a870          # GPU - muted amber
export STAT_CPU=0xffd89860          # CPU - warm orange
export STAT_DATE=0xffe78a53         # DATE - saturated orange

# Backgrounds
export BG_COLOR=0xcc1a1a1a

# Workspace colours - white with tiling accent
export WS_FOCUSED=0xffffffff         # White - visible on monitor
export WS_UNFOCUSED=0x80ffffff       # 50% white - has apps but not visible
export WS_EMPTY=0x40ffffff           # 25% white - initial state (hidden when empty)
export WS_INACTIVE=0x40ffffff        # 25% white - legacy alias
export WS_TILING=0xff99FFD6          # Mint green - tiling mode indicator

# Graph
export GRAPH_LINE=0x66ffffff
export GRAPH_FILL=0x44ffffff

# Threshold colours for CPU/GPU/MEM
export STAT_NORMAL=0xccffffff        # Normal (white)
export STAT_WARN=0xffFFB380          # 75-90% (pastel orange)
export STAT_CRIT=0xffFF8080          # 90-100% (pastel red)

# Ping colours - mint accent for good, Bathory palette for warnings
export PING_GOOD=0xff99ffd6         # Mint green (brightest in gradient)
export PING_MED=0xfffbbf24          # Warning yellow
export PING_BAD=0xffef4444          # Error red

# VPN and DNS indicators
export VPN_ACTIVE=0xffffffff
export VPN_INACTIVE=0xffef4444
export DNS_ACTIVE=0xffffffff
export DNS_INACTIVE=0xffef4444

# Focus mode colours (reuse existing palette)
export FOCUS_ON=$WS_TILING             # 0xff99FFD6 - Mint green (on-task)
export FOCUS_OFF=$STAT_WARN            # 0xffFFB380 - Pastel orange (off-task)
export FOCUS_ALERT=$STAT_CRIT          # 0xffFF8080 - Pastel red (off-task 15m+)
