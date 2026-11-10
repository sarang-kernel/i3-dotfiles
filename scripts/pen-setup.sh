#!/bin/bash
# pen-setup: map the ASUS stylus and touchscreen to the internal panel (run once at login by i3).
#   Needs: xinput (and xsetwacom, optional, for the pressure curve). No root.
#   What it does: maps the stylus (ELAN9008:00 04F3:40FD Stylus) and the touchscreen to the panel, enables the stylus, sets a linear
#   pressure curve, makes pen button 2 a right click and button 3 a middle click, and ignores touch while typing.
#   Exits 1 with "Pen not detected" when the stylus is not present. The panel name (eDP-1 or eDP-2) is looked up at run time.

PEN="ELAN9008:00 04F3:40FD Stylus"
TOUCH="ELAN9008:00 04F3:40FD"
SCREEN="$(xrandr --current | awk '/^eDP[^ ]* connected/{print $1; exit}')"; SCREEN=${SCREEN:-eDP-1}   # eDP-1 or eDP-2, depends on GPU driver order

log() {
	echo "[pen-setup] $1"
}

if ! xinput list --name-only | grep -Fxq "$PEN"; then
	log "Pen not detected"
	exit 1
fi

log "Configuring ASUS pen..."

# Map stylus to internal display
xinput map-to-output "$PEN" "$SCREEN"

# Optional: map touchscreen too
xinput map-to-output "$TOUCH" "$SCREEN"

# Enable stylus
xinput enable "$PEN"

# Ensure pressure events are enabled
xsetwacom --set "$PEN" PressureCurve 0 0 100 100 2>/dev/null

# Button mapping
# Pen button 1 -> right click
# Pen button 2 -> middle click

xinput set-button-map "$PEN" 1 3 2

# Disable touch while pen is near screen (if supported)
xinput set-prop "$TOUCH" \
	"libinput Disable While Typing Enabled" 1 \
	2>/dev/null

log "Pen ready"
