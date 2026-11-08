#!/usr/bin/env bash
# rog-tune: caffeine. While on: no auto-lock, no screen blanking (closing the lid still suspends, Super+Shift+L still locks).
#   caffeine.sh toggle | on | off | status
F=${XDG_STATE_HOME:-$HOME/.local/state}/caffeine; mkdir -p "${F%/*}"
case ${1:-toggle} in
toggle) if [[ -e $F ]]; then exec "$0" off; else exec "$0" on; fi ;;
on) : >"$F"; xset s off -dpms 2>/dev/null ;;
off) rm -f "$F"; "$HOME/.config/scripts/power-watch.sh" timers ;;
status) if [[ -e $F ]]; then echo on; elif [[ -e ${XDG_RUNTIME_DIR:-/tmp}/autocaffeine.on ]]; then echo auto; else echo off; fi ;;
esac
