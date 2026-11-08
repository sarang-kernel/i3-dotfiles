#!/usr/bin/env bash
# rog-tune: automatic caffeine. The screen stays on and unlocked while a window is fullscreen on the visible workspace (video,
# presentations) or an app is using the microphone (calls); otherwise the normal lock/blank timers apply. Music does not count.
# Event driven (i3 + PulseAudio events); the manual toggle (caffeine.sh) works independently of it.
RT=${XDG_RUNTIME_DIR:-/tmp}; PIDF=$RT/autocaffeine.pid; MARK=$RT/autocaffeine.on
if [[ -r $PIDF ]] && grep -q autocaffeine "/proc/$(<"$PIDF")/cmdline" 2>/dev/null; then pkill -P "$(<"$PIDF")" 2>/dev/null; kill "$(<"$PIDF")" 2>/dev/null; fi
echo $$ >"$PIDF"
[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"
if [[ ${AUTOCAFFEINE:-1} == 0 ]]; then rm -f "$MARK"; "$HOME/.config/scripts/power-watch.sh" timers; exit 0; fi
fullscreen() {
	local ws; ws=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused) | .name')
	i3-msg -t get_tree | jq -e --arg n "$ws" '[.. | objects | select(.type == "workspace" and .name == $n) | .. | objects | select(.window != null and .fullscreen_mode == 1)] | length > 0' >/dev/null
}
calling() {
	pactl -f json list source-outputs 2>/dev/null | jq -e '[.[] | select(.corked == false) | select((.properties["application.name"] // "") | test("peak|pavucontrol|volume|polybar|mission";"i") | not)] | length > 0' >/dev/null
}
update() {
	if fullscreen || calling; then
		[[ -e $MARK ]] || { : >"$MARK"; xset s off -dpms 2>/dev/null; }
	elif [[ -e $MARK ]]; then
		rm -f "$MARK"; "$HOME/.config/scripts/power-watch.sh" timers
	fi
}
fifo=$(mktemp -u "$RT/ac.XXXXXX"); mkfifo "$fifo"; exec 3<>"$fifo"; rm -f "$fifo"
cleanup() { kill $(jobs -p) 2>/dev/null; rm -f "$MARK"; }
trap cleanup EXIT; trap 'exit 0' TERM INT
pactl subscribe 2>/dev/null | grep --line-buffered "source-output" >&3 &
i3-msg -t subscribe -m '["window","workspace"]' 2>/dev/null | grep --line-buffered -E '"change":"(fullscreen_mode|close)"|"current":' >&3 &
update
while :; do
	read -r -t 120 -u 3 _ || true
	sleep 0.4; while read -r -t 0.05 -u 3 _; do :; done    # one evaluation per burst of events
	update
done
