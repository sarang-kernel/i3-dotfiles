#!/usr/bin/env bash
# rog-tune: (re)create the timer that changes the wallpaper every WALL_EVERY minutes (0 = never; set in Settings -> Wallpaper)
[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"
systemctl --user stop rog-wallpaper.timer rog-wallpaper.service 2>/dev/null
((${WALL_EVERY:-0} > 0)) || exit 0
env_args=(); for v in DISPLAY XAUTHORITY XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS; do [[ -n ${!v:-} ]] && env_args+=(--setenv="$v=${!v}"); done
systemd-run --user --collect --unit=rog-wallpaper --on-active="${WALL_EVERY}m" --on-unit-active="${WALL_EVERY}m" --timer-property=AccuracySec=10s \
	"${env_args[@]}" -- "$HOME/.config/wallpaper-config/wallpaper-cycle.sh" >/dev/null 2>&1
