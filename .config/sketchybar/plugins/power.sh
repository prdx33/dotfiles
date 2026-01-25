#!/bin/bash

# Power plugin - shows live power draw in watts

# Try to get current power from ioreg
POWER_INFO=$(ioreg -r -c AppleSmartBattery 2>/dev/null)

# Get instantaneous amperage and voltage
AMPS=$(echo "$POWER_INFO" | grep '"InstantAmperage"' | grep -oE '[-0-9]+' | head -1)
VOLTS=$(echo "$POWER_INFO" | grep '"Voltage"' | grep -oE '[0-9]+' | head -1)

if [[ -n "$AMPS" && -n "$VOLTS" ]]; then
    # Convert to watts (mA * mV / 1000000)
    # Negative amps = discharging, positive = charging
    WATTS=$(echo "scale=0; ($AMPS * $VOLTS) / 1000000" | bc 2>/dev/null)
    WATTS=${WATTS#-}  # Remove negative sign

    if [[ "$AMPS" -lt 0 ]]; then
        # Discharging
        sketchybar --set $NAME label="🔋${WATTS}W"
    else
        # Charging/plugged in - show adapter watts
        ADAPTER_WATTS=$(echo "$POWER_INFO" | grep -oE '"Watts"=[0-9]+' | head -1 | grep -oE '[0-9]+')
        [[ -n "$ADAPTER_WATTS" ]] && WATTS=$ADAPTER_WATTS
        sketchybar --set $NAME label="⚡${WATTS}W"
    fi
else
    sketchybar --set $NAME label="⚡--W"
fi
