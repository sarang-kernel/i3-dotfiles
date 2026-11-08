#!/bin/sh
# rog-tune: polybar mic indicator, event driven (no polling). Always visible: quiet grey = live, red = muted. Click toggles.
show() { if pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -q yes; then echo "%{F#e06c5a}  muted%{F-}"; else echo "%{F#9b9084}  live%{F-}"; fi; }
show
f=$(mktemp -u "${XDG_RUNTIME_DIR:-/tmp}/micfollow.XXXXXX"); mkfifo "$f"
pactl subscribe >"$f" 2>/dev/null & P=$!
trap 'kill "$P" 2>/dev/null; rm -f "$f"; exit 0' INT TERM HUP    # polybar restarts must not leave a pactl behind
trap 'kill "$P" 2>/dev/null; rm -f "$f"' EXIT
while read -r l; do case $l in *source*|*server*) show ;; esac; done <"$f"
