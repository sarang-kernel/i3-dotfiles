#!/usr/bin/env bash
# rog-tune: is hardware video decoding available? Needs libva-utils (sudo pacman -S libva-utils). Read-only.
command -v vainfo >/dev/null || { echo "Install libva-utils first:  sudo pacman -S libva-utils   (then run this again)"; exit 1; }
echo "== driver and decode profiles (VLD = hardware decode):"
LIBVA_DRIVER_NAME=${LIBVA_DRIVER_NAME:-radeonsi} vainfo 2>&1 | grep -E "Driver version|VAProfile(H264|HEVC|VP9|AV1)" | sed 's/^/  /'
echo
echo "== where it is enabled:"
for f in "$HOME"/.config/chrome-flags.conf "$HOME"/.config/google-chrome-flags.conf; do [[ -r $f ]] && { echo "  $f:"; grep -E "vaapi|VaapiVideo|hardware" "$f" | sed 's/^/    /'; }; done
grep -rhs "media.ffmpeg.vaapi" "$HOME"/.zen/*/user.js "$HOME"/.config/mozilla/firefox/*/user.js 2>/dev/null | sed 's/^/  firefox-family user.js: /'
echo
echo "To turn it on for the browsers: ~/rog-tune/rog-lean-session.sh --apply vaapi   (then restart them). Check chrome://gpu or about:support after."
