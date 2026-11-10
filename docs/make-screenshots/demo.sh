#!/usr/bin/env bash
. ~/shots/vx/env.sh
cd ~/shots/vx; rm -f demo.mp4 demo.gif
ffmpeg -nostdin -loglevel error -y -f x11grab -framerate 10 -video_size 2560x1600 -i :99 -vf scale=1280:-1 -c:v libx264 -preset veryfast -crf 27 -pix_fmt yuv420p demo.mp4 &
FF=$!
sleep 2
q() { xdotool key ctrl+a BackSpace; sleep 0.4; xdotool type --delay 150 "$1"; sleep "${2:-2.8}"; }
i3-msg "[class=demo3] focus" >/dev/null
~/.config/scripts/rog-ui.sh spotlight; sleep 2
q "settings"; q "15% of 80"; q "5 km in mi"; q ":smile"; q "timer 25m"; q "c demo"
q "spotlight.py" 1.5; xdotool key ctrl+y; sleep 3.5; xdotool key Escape; sleep 1
q "> uname -a"; q "w demo"
xdotool key alt+a; sleep 3; xdotool key Escape; sleep 0.8; xdotool key Escape; sleep 1.5
python3 ~/.config/scripts/power-menu.py & sleep 4; xdotool key Escape; sleep 1.5
i3-msg "[class=demo1] focus" >/dev/null; sleep 1.5
i3-msg focus parent >/dev/null; i3-msg layout tabbed >/dev/null; sleep 3
i3-msg layout stacking >/dev/null; sleep 3; i3-msg layout splitv >/dev/null; sleep 2
i3-msg workspace 2 >/dev/null; sleep 2; i3-msg workspace 1 >/dev/null; sleep 2
~/.config/scripts/rog-ui.sh settings; sleep 12; pkill -xf "python3 $HOME/.config/scripts/settings.py"; sleep 2
kill -INT $FF; wait $FF 2>/dev/null
ffmpeg -nostdin -loglevel error -y -i demo.mp4 -vf "fps=8,scale=960:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=96[p];[b][p]paletteuse=dither=bayer:bayer_scale=4" demo.gif
ls -la demo.mp4 demo.gif > out/demo-done
