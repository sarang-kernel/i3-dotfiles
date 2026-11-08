#!/usr/bin/env bash
# Measure real battery draw (watts). UNPLUG the charger first, then leave the laptop alone while it runs: screen on, nothing open that
# changes (no video, no builds). Caffeine is switched on for the run so the screen stays on, and put back afterwards.
#   ~/rog-tune/power-compare.sh [modes|refresh|all]     modes: Quiet / Balanced / Performance (about 8 min)
#                                                       refresh: a static desktop at 60 / 90 / 120 / 165 Hz in Balanced mode (about 6 min)
#   SETTLE=45 DUR=120 seconds per step (shorten for a quick look)
WHAT=${1:-all}; SETTLE=${SETTLE:-45} DUR=${DUR:-120}
PM=$HOME/.config/scripts/power-mode.sh; CAF=$HOME/.config/scripts/caffeine.sh; PW=$HOME/.config/scripts/power-watch.sh
PAUSE=${XDG_RUNTIME_DIR:-/tmp}/display-agent.pause
bat=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
[[ -n $bat ]] || { echo "no battery found"; exit 1; }
[[ $(<"$bat/status") == Discharging ]] || { echo "The battery is not discharging (status: $(<"$bat/status")). Unplug the charger and run again."; exit 1; }
watts() {
	if [[ -r $bat/power_now ]] && (($(<"$bat/power_now") > 0)); then awk -v p="$(<"$bat/power_now")" 'BEGIN{printf "%.3f", p/1e6}'
	else awk -v i="$(<"$bat/current_now")" -v v="$(<"$bat/voltage_now")" 'BEGIN{printf "%.3f", i*v/1e12}'; fi
}
orig=$("$PM" status | cut -d= -f2); caf_before=$("$CAF" status 2>/dev/null)
restore() { rm -f "$PAUSE"; "$PM" "$orig" >/dev/null 2>&1; [[ $caf_before == off ]] && "$CAF" off >/dev/null 2>&1; "$PW" display >/dev/null 2>&1; }
trap 'restore; exit' INT TERM
"$CAF" on >/dev/null 2>&1
out=$HOME/rog-tune/power-compare.txt; : >"$out"
sample() { # label
	local sum=0 n=0 end=$((SECONDS + DUR))
	while ((SECONDS < end)); do sum=$(awk -v s="$sum" -v w="$(watts)" 'BEGIN{print s+w}'); n=$((n + 1)); sleep 5; done
	echo "  $1: $(awk -v s="$sum" -v n="$n" 'BEGIN{printf "%.2f", s/n}') W average ($n samples)" | tee -a "$out"
}
echo "battery $(<"$bat/capacity") %. $SETTLE s settle + $DUR s per step. Hands off."
if [[ $WHAT == modes || $WHAT == all ]]; then
	echo "== modes" | tee -a "$out"
	for m in quiet balanced performance; do "$PM" "$m" >/dev/null 2>&1; sleep "$SETTLE"; sample "$m"; done
fi
if [[ $WHAT == refresh || $WHAT == all ]]; then
	echo "== refresh rate, static desktop, Balanced mode (the display agent is paused)" | tee -a "$out"
	: >"$PAUSE"; "$PM" balanced >/dev/null 2>&1
	eval "$(sed -n '/^set_refresh() {/,/^}/p' "$PW")"
	for hz in 60 90 120 165; do set_refresh "$hz"; sleep "$SETTLE"; sample "${hz} Hz"; done
	echo "  (if 60 Hz is not clearly below the higher rates, adaptive refresh saves nothing here: switch it off in Settings -> Display)" | tee -a "$out"
fi
restore
echo "Restored your battery mode ($orig) and the screen timers. Saved to $out"
