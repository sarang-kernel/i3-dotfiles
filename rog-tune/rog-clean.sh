#!/usr/bin/env bash
# Throw away regenerable caches on rog (no sudo). Dry run by default: shows sizes.
#   ~/rog-tune/rog-clean.sh [--apply] [--trash] [--browsers]
# Removes: Ferdium per-service Cache / Code Cache / GPUCache / Service Worker caches (~5 GB; the apps rebuild them, I stay
# logged in), ~/.cache/{pip,pnpm,yay,ms-playwright}. Never touches logins, cookies, settings or the browsers' own caches.
# --browsers also clears the web caches of Chrome, Firefox, Zen, qutebrowser and the Electron chat apps, but only for apps that are NOT
# running right now (their logins, history and settings are never touched; pages just load a little slower once).
# --trash also empties ~/.local/share/Trash (3.4 GB). Refuses while Ferdium is running.
set -euo pipefail
APPLY=0 TRASH=0 BROWSERS=0
for a in "$@"; do case $a in --apply) APPLY=1 ;; --trash) TRASH=1 ;; --browsers) BROWSERS=1 ;; *) sed -n '2,8p' "$0"; exit 1 ;; esac; done
T=()
for d in "$HOME"/.config/Ferdium/Partitions/*/{Cache,"Code Cache",GPUCache,"Service Worker/CacheStorage","Service Worker/ScriptCache",DawnGraphiteCache,DawnWebGPUCache}; do [[ -d $d ]] && T+=("$d"); done
for d in pip pnpm yay ms-playwright; do [[ -d $HOME/.cache/$d ]] && T+=("$HOME/.cache/$d"); done
if ((BROWSERS)); then
	for pair in google-chrome:chrome google-chrome:google-chrome zen:zen mozilla:firefox qutebrowser:qutebrowser; do
		dir=${pair%%:*} proc=${pair#*:}
		[[ -d $HOME/.cache/$dir ]] || continue
		if pgrep -x "$proc" >/dev/null || pgrep -f "[/]$proc( |$)" >/dev/null; then echo "skip (running): ~/.cache/$dir"; continue; fi
		[[ " ${T[*]} " == *" $HOME/.cache/$dir "* ]] || T+=("$HOME/.cache/$dir")
	done
	for app in discord teams-for-linux obsidian Signal; do
		pgrep -xi "${app%%-*}" >/dev/null && { echo "skip (running): $app"; continue; }
		for c in Cache "Code Cache" GPUCache DawnGraphiteCache DawnWebGPUCache; do [[ -d $HOME/.config/$app/$c ]] && T+=("$HOME/.config/$app/$c"); done
	done
fi
((TRASH)) && [[ -d $HOME/.local/share/Trash ]] && T+=("$HOME/.local/share/Trash/files" "$HOME/.local/share/Trash/info")
total=$(du -sck "${T[@]}" 2>/dev/null | tail -n1 | cut -f1)
printf '%s\n' "${T[@]}" | while read -r d; do printf '%8s  %s\n' "$(du -sh "$d" 2>/dev/null | cut -f1)" "${d/#$HOME/~}"; done | sort -rh | head -25
echo ":: total $((total / 1024)) MiB"
((APPLY)) || { echo ":: dry run — nothing deleted. Re-run with --apply."; exit 0; }
if pgrep -x ferdium >/dev/null; then echo "Close Ferdium first, then re-run." >&2; exit 1; fi
for d in "${T[@]}"; do find "$d" -mindepth 1 -delete 2>/dev/null || true; done
echo ":: done"
