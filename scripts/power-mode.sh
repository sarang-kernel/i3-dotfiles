#!/usr/bin/env bash
# rog-tune: performance mode for the power source I am on right now (saved, so it is also what plug/unplug restores)
#   power-mode.sh quiet | balanced | performance | cycle | status
#   Quiet       least battery: power-saver CPU profile (CPU capped near 4 GHz, quiet fans), 60 Hz, no blur or dimming
#   Balanced    everyday
#   Performance CPU and fans unrestricted (louder, hotter)
#   Defaults: Balanced on AC, Quiet on battery. Spotlight and Settings change the same thing.
ENV=$HOME/.config/rog/settings.env; mkdir -p "${ENV%/*}"; touch "$ENV"
ac_online() { local f; for f in /sys/class/power_supply/*/online; do [[ -r $f && $(<"${f%online}type") == Mains ]] && { [[ $(<"$f") == 1 ]]; return; }; done; return 0; }
if ac_online; then key=MODE_AC def=balanced; else key=MODE_BAT def=quiet; fi
cur=$(grep -m1 "^$key=" "$ENV" | cut -d'"' -f2); cur=${cur:-$def}
case ${1:-status} in
status) echo "$key=$cur"; exit 0 ;;
cycle) case $cur in quiet) new=balanced ;; balanced) new=performance ;; *) new=quiet ;; esac ;;
quiet | balanced | performance) new=$1 ;;
*) sed -n '2,8p' "$0"; exit 1 ;;
esac
rm -f "${XDG_RUNTIME_DIR:-/tmp}/autoquiet.on"      # you chose a mode on purpose: that beats the automatic low-battery Quiet
if grep -q "^$key=" "$ENV"; then sed -i "s|^$key=.*|$key=\"$new\"|" "$ENV"; else printf '%s="%s"\n' "$key" "$new" >>"$ENV"; fi
exec "$HOME/.config/scripts/power-watch.sh" display
