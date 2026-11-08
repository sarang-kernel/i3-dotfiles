#!/usr/bin/env bash
# rog-tune: lock with the current wallpaper (blurred and darkened by login-bg.sh; i3lock only reads PNG).
# With i3lock-color installed it looks like the macOS lock screen: date and large thin clock on top, round ring with your name at the bottom;
# with plain i3lock it falls back to the simple lock, and so does it if this i3lock-color build rejects an option.
img=$HOME/.cache/lock-bg.png
base=(--nofork --ignore-empty-password --show-failed-attempts -c 14110f)
[[ -f $img ]] && base+=(-i "$img")
if i3lock --version 2>&1 | grep -q 'Raymond Li'; then
	acc=$(grep -oP '^ACCENT_HEX="#\K[0-9a-fA-F]{6}' "$HOME/.config/rog/settings.env" 2>/dev/null); acc=${acc:-c47f1c}
	# macOS-style: date and big thin time centred near the top, round "avatar" ring with the name at the bottom centre
	who=$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1); who=${who:-$USER}; who=${who^}
	rich=(--clock --indicator --radius=54 --ring-width=3
		--time-str="%H:%M" --date-str="%A %-d %B" --time-font="Noto Sans Light" --date-font="Noto Sans Medium"
		--time-size=150 --date-size=34 --time-pos="w/2:h*0.27" --date-pos="w/2:h*0.14"
		--time-color=ffffffee --date-color=ffffffd9 --time-align=0 --date-align=0
		--ind-pos="w/2:h*0.80"
		--greeter-text="$who" --greeter-font="Noto Sans Medium" --greeter-size=22 --greeter-color=ffffffee --greeter-pos="w/2:h*0.80+100" --greeter-align=0
		--inside-color=ffffff26 --ring-color=ffffff40 --line-color=00000000 --separator-color=00000000
		--keyhl-color=ffffffee --bshl-color=ffffff77
		--insidever-color=ffffff40 --ringver-color=ffffffcc
		--insidewrong-color=e8a07a40 --ringwrong-color=e8a07aff
		--verif-text="" --noinput-text="" --lock-text="" --lockfailed-text="" --wrong-text="Incorrect password" --wrong-font="Noto Sans Medium" --wrong-size=20 --wrong-color=ffffffee --wrong-pos="w/2:h*0.80+140"
		--pass-media-keys --pass-volume-keys)
	t0=$(date +%s%N)
	i3lock "${base[@]}" "${rich[@]}"; rc=$?
	((rc == 0 || ($(date +%s%N) - t0) > 2000000000)) && exit "$rc"
fi
exec i3lock "${base[@]}"
