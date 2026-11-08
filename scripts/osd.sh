#!/usr/bin/env bash
# rog-tune: volume / mic / brightness actions. Silent: no bars, no popups (the bar shows the state).
set -u
case $1 in
vol)
	case $2 in
	up) pactl set-sink-mute @DEFAULT_SINK@ 0; pactl set-sink-volume @DEFAULT_SINK@ +5% ;;
	down) pactl set-sink-volume @DEFAULT_SINK@ -5% ;;
	mute) pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
	esac ;;
mic) pactl set-source-mute @DEFAULT_SOURCE@ toggle ;;
bri)
	BL=(); [[ -d /sys/class/backlight/nvidia_wmi_ec_backlight ]] && BL=(-d nvidia_wmi_ec_backlight)
	case $2 in
	up) brightnessctl -q "${BL[@]}" set +5% ;;
	down) brightnessctl -q -n1 "${BL[@]}" set 5%- ;;
	up1) brightnessctl -q "${BL[@]}" set +1% ;;
	down1) brightnessctl -q -n1 "${BL[@]}" set 1%- ;;
	esac
	# remember it: the next login restores it (the login screen may have been raised to stay readable)
	mkdir -p "$HOME/.local/state/rog"; brightnessctl "${BL[@]}" -m | cut -d, -f4 | tr -d '%' >"$HOME/.local/state/rog/brightness" ;;
esac
