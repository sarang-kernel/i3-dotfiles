#!/usr/bin/env bash
# rog-tune: follow the accelerometer. Panel + touchscreen + pen rotate together.
#   autorotate.sh            run (event-driven, one instance)
#   autorotate.sh lock       toggle "stay put" (Super+Shift+O)
LOCK=${XDG_STATE_HOME:-$HOME/.local/state}/autorotate.lock; mkdir -p "${LOCK%/*}"
if [[ ${1:-} == lock ]]; then
	if [[ -e $LOCK ]]; then rm -f "$LOCK"; else : >"$LOCK"; fi
	exit 0
fi
PIDF=${XDG_RUNTIME_DIR:-/tmp}/autorotate.pid
if [[ -r $PIDF ]] && grep -q autorotate "/proc/$(<"$PIDF")/cmdline" 2>/dev/null; then
	pkill -P "$(<"$PIDF")" 2>/dev/null; kill "$(<"$PIDF")" 2>/dev/null
fi
echo $$ >"$PIDF"
SCREEN=$(xrandr --query | awk '/ connected/{print $1; exit}'); SCREEN=${SCREEN:-eDP-1}
CURRENT=
apply() {
	[[ -e $LOCK || $1 == "$CURRENT" ]] && return
	local r m
	case $1 in
	normal) r=normal m="1 0 0 0 1 0 0 0 1" ;;
	left-up) r=left m="0 -1 1 1 0 0 0 0 1" ;;
	right-up) r=right m="0 1 0 -1 0 1 0 0 1" ;;
	bottom-up) r=inverted m="-1 0 1 0 -1 1 0 0 1" ;;
	*) return ;;
	esac
	CURRENT=$1
	xrandr --output "$SCREEN" --rotate "$r"
	xinput list --name-only | grep -iE 'touchscreen|stylus|pen|^ELAN' | grep -viE 'touchpad|keyboard|mouse' |
		while read -r d; do xinput set-prop "$d" "Coordinate Transformation Matrix" $m; done
	~/.config/scripts/nightlight.sh reapply 2>/dev/null   # a rotation can reset the tint
}
# the first line is "Has accelerometer (orientation: X ...)", later ones are "orientation changed: X"
monitor-sensor --accel | while read -r line; do
	[[ $line =~ orientation(\ changed)?:\ ([a-z-]+) ]] && apply "${BASH_REMATCH[2]}"
done
