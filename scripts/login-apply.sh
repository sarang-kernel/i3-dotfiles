#!/usr/bin/env bash
# rog-tune: things that happen once per login (not on every i3 restart)
[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"
if [[ ${MIC_MUTE_LOGIN:-0} == 1 ]]; then sleep 3; pactl set-source-mute @DEFAULT_SOURCE@ 1; fi
# put the screen back to the brightness I chose last (the login screen raises a nearly-dark screen so it can be read)
b=$HOME/.local/state/rog/brightness
if [[ -r $b ]] && [[ $(<"$b") =~ ^[0-9]+$ ]]; then
	BL=(); [[ -d /sys/class/backlight/nvidia_wmi_ec_backlight ]] && BL=(-d nvidia_wmi_ec_backlight)
	brightnessctl -q -n1 "${BL[@]}" set "$(<"$b")%"
fi
