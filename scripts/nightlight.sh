#!/usr/bin/env bash
# rog-tune: night tint through the display's gamma ramp (no extra packages, no popups).
#   nightlight.sh toggle | on | off | auto | status | reapply | daemon
STATE=${XDG_STATE_HOME:-$HOME/.local/state}/nightlight; mkdir -p "$STATE"
MODE=$STATE/mode            # auto | on | off
[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"   # Settings app: NIGHT_GAMMA (tint), NIGHT_START/END
TINT=${NIGHTLIGHT_TINT:-${NIGHT_GAMMA:-1.0:0.81:0.65}}    # about 4000 K by default
START=${NIGHT_START:-19} END=${NIGHT_END:-7}              # default: same split as my day/night wallpapers
out=$(xrandr --query | awk '/ connected/{print $1; exit}'); out=${out:-eDP-1}
mode() { cat "$MODE" 2>/dev/null || echo auto; }
want() {
	case $(mode) in on) echo on ;; off) echo off ;;
	*) local h=$((10#$(date +%H))); ((h >= START || h < END)) && echo on || echo off ;; esac
}
apply() { if [[ $(want) == on ]]; then xrandr --output "$out" --gamma "$TINT"; else xrandr --output "$out" --gamma 1:1:1; fi; }
case ${1:-status} in
toggle) if [[ $(want) == on ]]; then echo off >"$MODE"; else echo on >"$MODE"; fi; apply ;;
on | off | auto) echo "$1" >"$MODE"; apply ;;
reapply) apply ;;
status) echo "mode=$(mode) tint=$(want)" ;;
daemon)
	PIDF=${XDG_RUNTIME_DIR:-/tmp}/nightlight.pid
	if [[ -r $PIDF ]] && grep -q nightlight "/proc/$(<"$PIDF")/cmdline" 2>/dev/null; then kill "$(<"$PIDF")" 2>/dev/null; fi
	echo $$ >"$PIDF"
	f=$(mktemp -u); mkfifo "$f"; exec 3<>"$f"; rm -f "$f"
	while :; do apply; read -r -t 300 -u 3 _ || true; done ;;
esac
