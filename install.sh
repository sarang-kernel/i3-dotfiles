#!/usr/bin/env bash
# Copies these dotfiles into ~/.config (existing files are saved to ~/.config-backup-<date> first).
# Root-level parts (login screen, kernel options, sysctl ...) are NOT touched here: see rog-tune/rog-tune.sh (dry run by default).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd); dest=$HOME/.config; bk=$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)
dirs=(i3 polybar picom kitty rofi i3lock wallpaper-config yazi rmpc touchegg Thunar btop mpv cava qalculate gtk-3.0 gtk-4.0 scripts rog spotlight dunst htop autostart)
for d in "${dirs[@]}"; do
	[[ -d $here/$d ]] || continue
	if [[ -e $dest/$d ]]; then mkdir -p "$bk"; cp -a "$dest/$d" "$bk/"; fi
	mkdir -p "$dest/$d"; cp -a "$here/$d/." "$dest/$d/"
done
mkdir -p "$dest/systemd/user"; cp -a "$here"/systemd/user/. "$dest/systemd/user/"
cp -a "$here/chrome-flags.conf" "$dest/"
chmod +x "$dest"/scripts/*.sh "$dest"/i3lock/lock.sh 2>/dev/null || true
[[ -d $bk ]] && echo "previous files saved in $bk"
echo "done. Reload i3 (Super+Shift+R). Root parts: sudo $here/rog-tune/rog-tune.sh   (dry run; add --apply)"
