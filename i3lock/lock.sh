#!/usr/bin/env bash
# rog-tune: lock with the current wallpaper (blurred and darkened by login-bg.sh; i3lock only reads PNG).
# With i3lock-color installed it also shows a clock, the date and an accent-coloured ring that fills as you type;
# with plain i3lock it falls back to the simple lock, and so does it if this i3lock-color build rejects an option.
img=$HOME/.cache/lock-bg.png
base=(--nofork --ignore-empty-password --show-failed-attempts -c 14110f)
[[ -f $img ]] && base+=(-i "$img")
if i3lock --version 2>&1 | grep -qi color; then
	acc=$(grep -oP '^ACCENT_HEX="#\K[0-9a-fA-F]{6}' "$HOME/.config/rog/settings.env" 2>/dev/null); acc=${acc:-c47f1c}
	rich=(--clock --indicator --radius=110 --ring-width=5
		--time-str="%H:%M" --date-str="%A, %d %B" --time-font="Noto Sans" --date-font="Noto Sans" --time-size=52 --date-size=17
		--time-color=eee9e0ff --date-color=eee9e0cc
		--inside-color=14110f55 --ring-color=eee9e033 --line-color=00000000 --separator-color=00000000
		--keyhl-color="${acc}ff" --bshl-color=e8a07aff
		--insidever-color=14110f88 --ringver-color="${acc}ff"
		--insidewrong-color=14110f88 --ringwrong-color=e8a07aff
		--verif-text="" --noinput-text="" --lock-text="" --lockfailed-text="" --wrong-text="Wrong password" --wrong-font="Noto Sans" --wrong-size=16 --wrong-color=e8a07aff
		--pass-media-keys --pass-volume-keys)
	t0=$(date +%s%N)
	i3lock "${base[@]}" "${rich[@]}"; rc=$?
	((rc == 0 || ($(date +%s%N) - t0) > 2000000000)) && exit "$rc"
fi
exec i3lock "${base[@]}"
