#!/bin/sh
# toggle-touchpad: turn the touchpad on or off (bound to the XF86TouchpadToggle key in i3/config).
#   Needs: xinput. No root. Finds the touchpad by name in `xinput list`, reads "Device Enabled" and flips it.

ID=$(xinput list | grep -i touchpad | grep -o 'id=[0-9]*' | cut -d= -f2)
STATE=$(xinput list-props "$ID" | grep 'Device Enabled' | awk '{print $4}')

if [ "$STATE" -eq 1 ]; then
	xinput disable "$ID"
else
	xinput enable "$ID"
fi
