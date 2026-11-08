#!/usr/bin/env bash
# rog-tune: apply the accent colour where Spotlight/Settings cannot reach: the bar's active workspace and the focused window's border.
#   accent.sh              apply what Settings -> General says (Amber, From the wallpaper, or Custom)
#   accent.sh wallpaper    (called when the wallpaper changes) work out the wallpaper's accent first, then apply
[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"
CACHE=$HOME/.cache/accent-wallpaper
if [[ ${1:-} == wallpaper ]]; then
	wp=$(cat "$HOME/.cache/current_wallpaper" 2>/dev/null); [[ -r $wp ]] || exit 0
	hex=$(magick "$wp" -resize 64x64! -depth 8 txt:- 2>/dev/null | python3 -c '
import sys, re, colorsys
best = None
for line in sys.stdin:
    m = re.search(r"\((\d+),(\d+),(\d+)", line)
    if not m: continue
    r, g, b = (int(x) / 255 for x in m.groups()); h, l, s = colorsys.rgb_to_hls(r, g, b)
    score = s * (1 - abs(l - 0.5) * 1.4)                       # saturated and neither too dark nor too light
    if best is None or score > best[0]: best = (score, h, s)
if best:
    h, s = best[1], max(best[2], 0.55)
    r, g, b = colorsys.hls_to_rgb(h, 0.55, min(s, 0.85)); print("#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255)))
')
	[[ $hex =~ ^#[0-9a-f]{6}$ ]] && echo "$hex" >"$CACHE"
	[[ ${ACCENT_MODE:-amber} == wallpaper ]] || exit 0
fi
case ${ACCENT_MODE:-amber} in
custom) hex=${ACCENT_HEX:-#e0a458} ;;
wallpaper) hex=$(cat "$CACHE" 2>/dev/null); hex=${hex:-#e0a458} ;;
*) hex=#e0a458 ;;
esac
[[ $hex =~ ^#[0-9a-fA-F]{6}$ ]] || exit 0
PB=$HOME/.config/polybar/config.ini; I3=$HOME/.config/i3/config
cur=$(grep -m1 -E '^mauve = ' "$PB" | sed -E 's/^mauve = //')
[[ $cur == "$hex" ]] && exit 0                      # nothing to change: no bar restart, no reload
sed -i -E "s/^mauve = .*/mauve = $hex/" "$PB"
sed -i -E "s/^(client\.focused[[:space:]]+)#[0-9a-fA-F]{6}( #[0-9a-fA-F]{6} #[0-9a-fA-F]{6} )#[0-9a-fA-F]{6} #[0-9a-fA-F]{6}/\1$hex\2$hex $hex/" "$I3"
polybar-msg cmd restart >/dev/null 2>&1; i3-msg reload >/dev/null 2>&1
