#!/bin/bash

# Claude API plugin - Anthropic Admin API billing period cost
# Whole dollars only, right-aligned

source "$CONFIG_DIR/colours.sh" 2>/dev/null || exit 0

# Add homebrew and nvm node to PATH (sketchybar has minimal env)
NVM_NODE="$HOME/.nvm/versions/node"
[[ -d "$NVM_NODE" ]] && export PATH="$(ls -d "$NVM_NODE"/*/bin 2>/dev/null | head -1):$PATH"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

CACHE_FILE="/tmp/sketchybar_claude_api"
CACHE_MAX_AGE=3600  # 1 hour in seconds

api_cost="--"
now=$(date +%s)

# Check cache age
use_cache=0
if [[ -f "$CACHE_FILE" ]]; then
    cache_time=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
    age=$((now - cache_time))
    if [[ $age -lt $CACHE_MAX_AGE ]]; then
        use_cache=1
    fi
fi

if [[ $use_cache -eq 1 ]]; then
    api_cost=$(cat "$CACHE_FILE" 2>/dev/null)
else
    # Get API key from 1Password
    api_key=$(op read "op://Dev/Anthropic Admin API Key/anthropic-admin-key" 2>/dev/null)
    if [[ -n "$api_key" ]]; then
        month_start=$(date -u "+%Y-%m-01T00:00:00Z")

        # Use usage_report (token counts) with manual cost calc
        # cost_report returns gross pre-discount amounts — unusable
        now_utc=$(date -u "+%Y-%m-%dT00:00:00Z")
        response=$(curl -s --max-time 15 \
            -H "x-api-key: $api_key" \
            -H "anthropic-version: 2023-06-01" \
            "https://api.anthropic.com/v1/organizations/usage_report/messages?starting_at=$month_start&ending_at=$now_utc&group_by[]=service_tier&group_by[]=model&bucket_width=1d&limit=31")

        if [[ -n "$response" ]]; then
            # Calculate net cost from token counts × published rates
            # Batch tier gets 50% discount on all rates
            total_cents=$(echo "$response" | python3 -c "
import json, sys
RATES = {
    'claude-3-5-haiku-20241022': (0.80, 4.00, 1.00, 0.08),
    'claude-haiku-4-5-20251001': (1.00, 5.00, 1.25, 0.10),
    'claude-sonnet-4-20250514':  (3.00, 15.00, 3.75, 0.30),
    'claude-sonnet-4-5-20250929':(3.00, 15.00, 3.75, 0.30),
    'claude-opus-4-6':           (15.00, 75.00, 18.75, 1.50),
}
DEFAULT = (3.00, 15.00, 3.75, 0.30)
data = json.load(sys.stdin)
total = 0
for day in data.get('data', []):
    for r in day.get('results', []):
        m = r.get('model', '')
        ri, ro, rcw, rcr = RATES.get(m, DEFAULT)
        d = 0.5 if r.get('service_tier') == 'batch' else 1.0
        cc = r.get('cache_creation', {})
        total += (
            r.get('uncached_input_tokens', 0) * ri * d +
            r.get('output_tokens', 0) * ro * d +
            (cc.get('ephemeral_5m_input_tokens', 0) + cc.get('ephemeral_1h_input_tokens', 0)) * rcw * d +
            r.get('cache_read_input_tokens', 0) * rcr * d
        ) / 1_000_000
print(int(total * 100))
" 2>/dev/null)
            if [[ -n "$total_cents" && "$total_cents" =~ ^[0-9]+$ && "$total_cents" -gt 0 ]]; then
                dollars=$((total_cents / 100))
                api_cost=$(printf "\$%d" "$dollars")
            fi
        fi

        echo "$api_cost" > "$CACHE_FILE"
    elif [[ -f "$CACHE_FILE" ]]; then
        api_cost=$(cat "$CACHE_FILE" 2>/dev/null)
    fi
fi

[[ -z "$api_cost" ]] && api_cost="--"

# Cost tier — sharp curve from $250, ceiling at $500
# Thresholds: 0-250 white, 250-300, 300-370, 370-430, 430-500, 500+
color=$TIER_0
if [[ "$api_cost" =~ ^\$([0-9]+)$ ]]; then
    d=${BASH_REMATCH[1]}
    if [[ $d -ge 500 ]]; then color=$TIER_5
    elif [[ $d -ge 430 ]]; then color=$TIER_4
    elif [[ $d -ge 370 ]]; then color=$TIER_3
    elif [[ $d -ge 300 ]]; then color=$TIER_2
    elif [[ $d -ge 250 ]]; then color=$TIER_1
    fi
fi

# Right-align within 4 chars
label=$(printf "%4s" "$api_cost")
# Respect idle fade — active (spending above threshold) dims to 70%, idle to 20%
if [[ -f /tmp/sketchybar_bar_faded ]]; then
    dim=$DIM_IDLE
    [[ "$color" != "$TIER_0" ]] && dim=$DIM_ACTIVE
    sketchybar --set claude_api label="$label" label.color=$dim \
               --set claude_api_label label.color=$dim 2>/dev/null
# Tier 4-5: whole cluster coloured. Below: only value.
elif [[ "$api_cost" =~ ^\$([0-9]+)$ ]] && [[ ${BASH_REMATCH[1]} -ge 430 ]]; then
    sketchybar --set claude_api label="$label" label.color="$color" \
               --set claude_api_label label.color="$color" 2>/dev/null
else
    sketchybar --set claude_api label="$label" label.color="$color" \
               --set claude_api_label label.color="$TIER_0" 2>/dev/null
fi
