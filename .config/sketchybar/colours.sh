#!/bin/bash

# Font - monospace
export FONT="Iosevka Extended"
export MONO_FONT="Iosevka Extended"

# Bar
export BAR_COLOR=0x80000000

# Text
export LABEL_COLOR=0xccffffff
export STAT_LABEL=0xccffffff

# Backgrounds
export BG_COLOR=0xcc1a1a1a

# Workspace colours - all white (no colour distinction)
export WS_FOCUSED=0xffffffff         # White - visible on monitor
export WS_UNFOCUSED=0x80ffffff       # 50% white - has apps but not visible
export WS_EMPTY=0x40ffffff           # 25% white - initial state (hidden when empty)
export WS_INACTIVE=0x40ffffff        # 25% white - legacy alias

# Graph
export GRAPH_LINE=0x66ffffff
export GRAPH_FILL=0x44ffffff

# Threshold colours for CPU/GPU/MEM
export STAT_NORMAL=0xccffffff        # Normal (white)
export STAT_WARN=0xffFFB380          # 75-90% (pastel orange)
export STAT_CRIT=0xffFF8080          # 90-100% (pastel red)

# Ping colours
export PING_GOOD=0xff4ade80
export PING_MED=0xfffbbf24
export PING_BAD=0xffef4444

# VPN and DNS indicators
export VPN_ACTIVE=0xffffffff
export VPN_INACTIVE=0xffef4444
export DNS_ACTIVE=0xffffffff
export DNS_INACTIVE=0xffef4444
