#!/usr/bin/env bash
# rog-tune: power-aware behaviour, event driven (upower). Re-applied on every plug/unplug.
#   AC:      Balanced mode (blur, 90 Hz), lock after 10 min / screen off after 15
#   battery: Quiet mode (power-saver, 60 Hz, no blur), lock after 2 min / screen off after 3
#   (modes and rates can be changed in Settings; see power-mode.sh)
#   power-watch.sh            run in the background (started by i3)
#   power-watch.sh once ac|bat|auto    apply once and exit (to try it)
#   power-watch.sh timers              re-apply only the lock/blank timers (caffeine uses it)
#   power-watch.sh display             re-apply only the performance mode, refresh rate and CPU profile (Settings and power-mode.sh use it)
#   power-watch.sh autoquiet           re-check the low-battery Quiet override now
#   power-watch.sh refresh             apply only the refresh rate that fits right now (Quiet / cinema / idle / my setting)
#   power-watch.sh rate                print my configured rate for the current power source (60 in Quiet)
PIDF=${XDG_RUNTIME_DIR:-/tmp}/power-watch.pid
PS=${ROG_PS:-/sys/class/power_supply}      # (overridable for tests)
AQ=${XDG_RUNTIME_DIR:-/tmp}/autoquiet.on
ac_online() {
	local f
	for f in "$PS"/*/online; do
		[[ -r $f && $(<"${f%online}type") == Mains ]] && { [[ $(<"$f") == 1 ]] && return 0 || return 1; }
	done
	return 0
}
set_refresh() { # any rate from 60 to 165 Hz: 60 and 165 are the panel's own modes; the rest use the same timings at another pixel clock
	local hz=$1 name clk
	if [[ $hz == 60 || $hz == 165 ]]; then xrandr --output eDP-1 --mode 2560x1600 --rate "$hz" 2>/dev/null && return 0; fi
	name=2560x1600_$hz
	if ! xrandr | grep -q "^   $name "; then
		clk=$(awk -v r="$hz" 'BEGIN{printf "%.3f", 2735*1732*r/1e6}')
		xrandr --newmode "$name" "$clk" 2560 2608 2640 2735 1600 1603 1609 1732 -HSync -VSync 2>/dev/null
		xrandr --addmode eDP-1 "$name" 2>/dev/null
	fi
	xrandr --output eDP-1 --mode "$name" 2>/dev/null || xrandr --output eDP-1 --mode 2560x1600 --rate 60
}
timers() { # screen lock / blank timers by power source; caffeine (a state file) switches them off
	command -v xset >/dev/null || return 0
	local want=$1
	[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"
	[[ $want == auto ]] && { ac_online && want=ac || want=bat; }
	if [[ -e ${XDG_STATE_HOME:-$HOME/.local/state}/caffeine || -e ${XDG_RUNTIME_DIR:-/tmp}/autocaffeine.on ]]; then xset s off -dpms; return 0; fi
	xset s noblank +dpms
	if [[ $want == ac ]]; then xset s $((${LOCK_AC:-10} * 60)) $((${LOCK_AC:-10} * 60)); xset dpms 0 0 $((${OFF_AC:-15} * 60))
	else xset s $((${LOCK_BAT:-2} * 60)) $((${LOCK_BAT:-2} * 60)); xset dpms 0 0 $((${OFF_BAT:-3} * 60)); fi
}
mode_of() { # ac|bat -> quiet|balanced|performance, from the Settings app (also reads the older profile names)
	local m
	[[ $1 == bat && -e $AQ ]] && { echo quiet; return; }          # low-battery override (see autoquiet_check)
	[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"
	if [[ $1 == ac ]]; then
		m=${MODE_AC:-}; [[ -n $m ]] || case ${AC_PROFILE:-balanced} in performance) m=performance ;; *) m=balanced ;; esac
	else
		m=${MODE_BAT:-}; [[ -n $m ]] || case ${BAT_PROFILE:-power-saver} in balanced) m=balanced ;; performance) m=performance ;; *) m=quiet ;; esac
	fi
	echo "$m"
}
style_apply() { # compositor look: blur and dimming only on AC and never in Quiet mode
	local want=$1 pc=$HOME/.config/picom pid
	if [[ $want == ac && $(mode_of ac) != quiet ]]; then ln -sfn picom-ac.conf "$pc/picom.conf"; else ln -sfn picom-bat.conf "$pc/picom.conf"; fi
	pid=$(pgrep -xo -u "$UID" picom) && kill -USR1 "$pid"
}
target_hz() { # ac|bat -> the refresh rate to use right now: cinema = the film rate; Quiet = 60; idle (adaptive) = the idle rate; else my setting
	local want=$1 m hz rt=${XDG_RUNTIME_DIR:-/tmp}
	[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"
	[[ -e $rt/cinema.on ]] && { if [[ -s $rt/cinema.hz ]]; then cat "$rt/cinema.hz"; else echo "${CINEMA_HZ:-71.928}"; fi; return; }      # a film in fullscreen beats everything, Quiet included
	m=$(mode_of "$want"); [[ $m == quiet ]] && { echo 60; return; }
	if [[ $want == ac ]]; then hz=${RATE_AC:-90}; else hz=${RATE_BAT:-60}; fi
	if [[ -e $rt/adaptive.low ]] && awk -v a="$hz" -v b="${IDLE_HZ:-60}" 'BEGIN{exit !(a>b)}'; then echo "${IDLE_HZ:-60}"; return; fi
	echo "$hz"
}
refresh_only() { # apply just the refresh rate (the display agent calls this); never while locked or with the screen off (a modeset could wake the panel)
	local want hz
	pgrep -x i3lock >/dev/null && return 0
	xset q 2>/dev/null | grep -q "Monitor is Off" && return 0
	ac_online && want=ac || want=bat
	hz=$(target_hz "$want")
	set_refresh "$hz"
	[[ -x $HOME/.config/scripts/nightlight.sh ]] && "$HOME/.config/scripts/nightlight.sh" reapply
}
display_apply() { # performance mode, refresh rate and CPU profile for ac|bat (defaults: AC balanced + 90 Hz, battery quiet + 60 Hz)
	local want=$1 hz m prof
	[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"
	m=$(mode_of "$want")
	hz=$(target_hz "$want")
	case $m in quiet) prof=power-saver ;; performance) prof=performance ;; *) prof=balanced ;; esac
	[[ -n ${ROG_DRY:-} ]] && { echo "display_apply $want mode=$m profile=$prof hz=$hz"; return; }
	set_refresh "$hz"
	command -v powerprofilesctl >/dev/null && powerprofilesctl set "$prof"
	style_apply "$want"
}
autoquiet_check() { # at low battery switch to Quiet until plugged in (or the charge is 5 points above the threshold); event driven
	local cap pct on
	[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"
	pct=${AUTOQUIET_PCT:-20}; on=${AUTOQUIET:-1}
	if ac_online || [[ $on != 1 ]]; then [[ -e $AQ ]] && { rm -f "$AQ"; ac_online && display_apply ac || display_apply bat; }; return 0; fi
	cap=$(cat "$PS"/BAT*/capacity 2>/dev/null | head -n1); [[ $cap =~ ^[0-9]+$ ]] || return 0
	if [[ ! -e $AQ ]] && ((cap <= pct)) && [[ $(mode_of bat) != quiet ]]; then : >"$AQ"; display_apply bat
	elif [[ -e $AQ ]] && ((cap > pct + 5)); then rm -f "$AQ"; display_apply bat; fi
}
last=
apply() {
	local want=$1
	[[ $want == auto ]] && { ac_online && want=ac || want=bat; }
	[[ $want == "$last" ]] && return
	last=$want
	display_apply "$want"
	timers "$want"
	[[ -x $HOME/.config/scripts/nightlight.sh ]] && "$HOME/.config/scripts/nightlight.sh" reapply
}
if [[ ${1:-} == once ]]; then apply "${2:-auto}"; exit 0; fi
if [[ ${1:-} == timers ]]; then timers auto; exit 0; fi
if [[ ${1:-} == autoquiet ]]; then autoquiet_check; exit 0; fi
if [[ ${1:-} == refresh ]]; then refresh_only; exit 0; fi
if [[ ${1:-} == rate ]]; then ac_online && w=ac || w=bat; m=$(mode_of "$w"); if [[ $m == quiet ]]; then echo 60; else . "$HOME/.config/rog/settings.env" 2>/dev/null; if [[ $w == ac ]]; then echo "${RATE_AC:-90}"; else echo "${RATE_BAT:-60}"; fi; fi; exit 0; fi
if [[ ${1:-} == display ]]; then ac_online && w=ac || w=bat; display_apply "$w"; [[ -x $HOME/.config/scripts/nightlight.sh ]] && "$HOME/.config/scripts/nightlight.sh" reapply; exit 0; fi
if [[ -r $PIDF ]] && grep -q power-watch "/proc/$(<"$PIDF")/cmdline" 2>/dev/null; then kill "$(<"$PIDF")" 2>/dev/null; fi
echo $$ >"$PIDF"
sleep 1
apply auto; autoquiet_check
coproc UPW { exec upower --monitor 2>/dev/null; }
trap 'kill "$UPW_PID" 2>/dev/null' EXIT; trap 'exit 0' TERM INT
while read -r _ <&"${UPW[0]}"; do apply auto; autoquiet_check; done
