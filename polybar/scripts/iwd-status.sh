#!/bin/bash
# iwd-status: polybar network module. Prints the connected network name (or "Disconnected") for the interface below.
#   Needs: iwctl (iwd). No root. The interface is hard-coded as wlan0; polybar runs it every 5 seconds (module/network).

# ~/.config/polybar/scripts/iwd-status.sh

IFACE="wlan0"

# Get connection state
CONNECTED=$(iwctl station "$IFACE" show | awk '/State/ {print $2}')
SSID=$(iwctl station "$IFACE" show | awk '/Connected network/ {print $3}')

# Output
if [[ "$CONNECTED" == "connected" && -n "$SSID" ]]; then
	echo " $SSID"
else
	echo "睊 Disconnected"
fi
