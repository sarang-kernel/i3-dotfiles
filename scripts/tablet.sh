#!/usr/bin/env bash
# rog-tune: tablet mode = an on-screen keyboard (onboard) docked at the bottom that appears when a text field gets focus.
# Off by default and after every login. Needs: sudo pacman -S onboard
#   tablet.sh toggle | on | off | status
command -v onboard >/dev/null || { echo "install onboard first: sudo pacman -S onboard" >&2; exit 1; }
running() { pgrep -x -u "$UID" onboard >/dev/null; }
on() {
	gsettings set org.onboard.auto-show enabled true
	gsettings set org.onboard.window docking-enabled true
	gsettings set org.onboard.window.landscape dock-expand true 2>/dev/null || true
	gsettings set org.onboard.window.portrait dock-expand true 2>/dev/null || true
	running || { onboard >/dev/null 2>&1 & disown; }
	rm -f "${XDG_STATE_HOME:-$HOME/.local/state}/autorotate.lock"   # tablets rotate
}
off() { pkill -x -u "$UID" onboard || true; }
case ${1:-toggle} in
toggle) if running; then off; else on; fi ;;
on) on ;; off) off ;; status) running && echo on || echo off ;;
esac
