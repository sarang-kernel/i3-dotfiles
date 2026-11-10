#!/usr/bin/env bash
cd ~/shots/vx
xrdb -merge <<< "Xft.dpi: 144"
xsetroot -cursor_name left_ptr
i3 -c ~/shots/vx/i3.conf >/tmp/vx-i3.log 2>&1 &
sleep 1.5
feh --no-fehbg --bg-scale "$(cat $HOME/.cache/current_wallpaper)"
polybar -c ~/shots/vx/polybar.ini toph >/tmp/vx-polybar.log 2>&1 &
python3 ~/.config/scripts/spotlight.py --daemon >/tmp/vx-spot.log 2>&1 &
wait
