#!/usr/bin/env bash
# rog-tune: screenshot → clipboard (PNG, pastes into browsers/chat/editors) + ~/Pictures. Silent.
# usage: shot.sh full|area|window|area-clip      (area-clip: clipboard only, no file)
set -u
mode=${1:-full}
[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"   # Settings: SHOT_SAVE=0 means clipboard only
dir=${XDG_PICTURES_DIR:-$HOME/Pictures}; mkdir -p "$dir"
name=screenshot_$(date +%Y-%m-%d_%H-%M-%S).png
case $mode in
area-clip) f=$(mktemp "${XDG_RUNTIME_DIR:-/tmp}/shot.XXXXXX.png"); keep=0 ;;
*) if [[ ${SHOT_SAVE:-1} == 0 ]]; then f=$(mktemp "${XDG_RUNTIME_DIR:-/tmp}/shot.XXXXXX.png"); keep=0; else f=$dir/$name; keep=1; fi ;;
esac
case $mode in
full) scrot -o "$f" ;;
window) scrot -o -u "$f" ;;
area | area-clip) scrot -o -s "$f" ;;
*) echo "usage: $0 full|area|window|area-clip" >&2; exit 2 ;;
esac || { rm -f "$f"; exit 0; }            # Esc during selection: quietly do nothing
[[ -s $f ]] || { rm -f "$f"; exit 0; }
xclip -selection clipboard -t image/png -i "$f"
((keep)) || rm -f "$f"
