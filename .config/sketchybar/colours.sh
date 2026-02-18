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

# Threshold colours for CPU/GPU/MEM (legacy, used by FOCUS_ refs)
export STAT_NORMAL=0xccffffff        # Normal (white)
export STAT_WARN=0xffFFB380          # 75-90% (pastel orange)
export STAT_CRIT=0xffFF8080          # 90-100% (pastel red)

# Activity tier colours (white → orange gradient, 5 levels)
# Ceiling colour matches STAT_DATE for visual consistency
export TIER_0=0xccffffff             # Idle - white
export TIER_1=0xfff0d0a8             # Low - warm cream
export TIER_2=0xffe8b080             # Moderate - light peach
export TIER_3=0xffe09860             # High - medium orange
export TIER_4=0xffe78a53             # Ceiling - bright orange (= STAT_DATE)
export TIER_5=0xffcf6b6b             # Critical - muted red (complementary)

# Fade dim levels (idle fade after 8s)
export DIM_IDLE=0x33ffffff           # 20% - idle stats when faded
export DIM_ACTIVE=0xB3ffffff         # 70% - active stats when faded

# Sunday accent (matches TIER_5 for palette cohesion)
export STAT_DATE_SUN=0xffcf6b6b

# Ping colours - mint accent for good, Bathory palette for warnings
export PING_GOOD=0xff99ffd6         # Mint green (brightest in gradient)
export PING_MED=0xfffbbf24          # Warning yellow
export PING_BAD=0xffef4444          # Error red

# VPN and DNS indicators
export VPN_ACTIVE=0xffffffff
export VPN_INACTIVE=0xffef4444
export DNS_ACTIVE=0xffffffff
export DNS_INACTIVE=0xffef4444

# Claude usage colours
export CLAUDE_CODE=0xffD4A574          # Warm tan (5hr window)
export CLAUDE_API=0xffA8C4B8           # Muted sage (API spend)
export WARNING_COLOUR=0xffFFB380       # Pastel orange (>$15 5hr)
export CRITICAL_COLOUR=0xffFF8080      # Pastel red (>$25 5hr)

# Focus mode colours (reuse existing palette)
export FOCUS_ON=$WS_TILING             # 0xff99FFD6 - Mint green (on-task)
export FOCUS_OFF=$STAT_WARN            # 0xffFFB380 - Pastel orange (off-task)
export FOCUS_ALERT=$STAT_CRIT          # 0xffFF8080 - Pastel red (off-task 15m+)
