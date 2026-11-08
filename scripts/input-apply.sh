#!/usr/bin/env bash
# rog-tune: apply touchpad / pointer / keyboard settings (at login, on i3 restart, and when Settings changes them)
[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"
export DISPLAY=${DISPLAY:-:0}
command -v xset >/dev/null && { xset r rate "${KEY_DELAY:-250}" "${KEY_RATE:-50}"; xset b off; }
command -v xinput >/dev/null || exit 0
xinput list --name-only | sort -u | while IFS= read -r d; do
	props=$(xinput list-props "$d" 2>/dev/null) || continue
	if grep -q "libinput Tapping Enabled (" <<<"$props"; then
		xinput set-prop "$d" "libinput Tapping Enabled" "${TP_TAP:-1}"
		xinput set-prop "$d" "libinput Natural Scrolling Enabled" "${TP_NATURAL:-0}"
		xinput set-prop "$d" "libinput Disable While Typing Enabled" "${TP_DWT:-1}" 2>/dev/null
	fi
	grep -q "libinput Accel Speed (" <<<"$props" && xinput set-prop "$d" "libinput Accel Speed" "${PTR_SPEED:-0}"
done
exit 0
