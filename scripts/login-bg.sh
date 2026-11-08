#!/usr/bin/env bash
# rog-tune: wallpaper hooks: keeps the login screen's wallpaper equal to the desktop wallpaper (the greeter runs as another user
# and can't read ~) and builds the lock-screen image
dst=/usr/share/backgrounds/rog/current
src=${1:-$(cat "$HOME/.cache/current_wallpaper" 2>/dev/null)}
[[ -n $src && -r $src ]] || exit 0
[[ -x $HOME/.config/scripts/accent.sh ]] && ( "$HOME/.config/scripts/accent.sh" wallpaper >/dev/null 2>&1 & )     # accent colour "from the wallpaper"
# lock screen: i3lock only reads PNG, so make a blurred, darkened one (once per wallpaper)
lock=$HOME/.cache/lock-bg.png; stamp=$HOME/.cache/lock-bg.src
if [[ $(cat "$stamp" 2>/dev/null) != "$src" ]]; then
	nice -n 19 magick "$src" -resize 2560x1600^ -gravity center -extent 2560x1600 -blur 0x14 -fill '#14110f' -colorize 35% "$lock.tmp.png" 2>/dev/null \
		&& mv -f "$lock.tmp.png" "$lock" && echo "$src" >"$stamp"
fi
[[ -w ${dst%/*} ]] || exit 0
cmp -s "$src" "$dst" || cp -f "$src" "$dst"
