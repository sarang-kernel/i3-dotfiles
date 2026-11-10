#!/usr/bin/env bash
. ~/shots/vx/env.sh
OUT=~/shots/vx/out; rm -rf $OUT; mkdir -p $OUT; cd $OUT
~/shots/vx/start.sh >/dev/null 2>&1
pkill -x i3-nagbar
kitty --class demo3 -e bash -c "cd ~/.config/nvim; nvim lua/plugins/lsp-config.lua" >/dev/null 2>&1 & sleep 2
kitty --class demo1 -e bash -c "clear; fastfetch --structure Title:Separator:OS:Kernel:WM:Terminal:Shell:CPU:GPU:Memory:Break:Colors; sleep 3000" >/dev/null 2>&1 & sleep 2
i3-msg split v >/dev/null
kitty --class demo2 -e bash -c "cd ~/spotlight-repo; git --no-pager log --oneline --decorate -12; exec bash" >/dev/null 2>&1 & sleep 3
sleep 8; i3-msg "[class=demo3] focus" >/dev/null; sleep 3
snap() { sleep 1; import -window root "$1.png"; }
spot() { name=$1; q=$2; shift 2
  ~/.config/scripts/rog-ui.sh spotlight; sleep 3
  [[ -n $q ]] && xdotool type --delay 140 "$q"; sleep 5
  for k in "$@"; do xdotool key $k; sleep 2.5; done
  snap "$name"; xdotool key Escape; sleep 0.8; xdotool key Escape; sleep 1.5
}
snap 00-desktop
for s in "hello world" "git commit -m fix-lock-screen" "demo clipboard text" "ssh rog"; do printf "%s" "$s" | xclip -selection clipboard; sleep 1.5; done
spot 01-apps "settings"
spot 02-maths "15% of 80"
spot 03-units "5 km in mi"
spot 04-emoji ":smile"
spot 05-timer "timer 25m"
spot 06-clipboard "c demo"
spot 07-files "spotlight.py"
spot 08-preview "spotlight.py" ctrl+y
spot 09-actions "lock"
spot 10-command "> uname -a"
spot 11-windows "w demo"
spot 12-allapps "" alt+a
spot 13-filters "spotlight kind:py modified:week"
python3 ~/.config/scripts/power-menu.py & sleep 7; snap 14-power; xdotool key Escape; sleep 1.5
~/.config/scripts/rog-ui.sh settings; sleep 16; snap 15-settings-tiled; pkill -xf "python3 $HOME/.config/scripts/settings.py"; sleep 1.5
i3-msg "[class=demo1] focus" >/dev/null; i3-msg focus parent >/dev/null; i3-msg layout tabbed >/dev/null; sleep 4; snap 16-tabbed
i3-msg layout stacking >/dev/null; sleep 4; snap 17-stacking
i3-msg layout splitv >/dev/null; sleep 1
~/.config/i3lock/lock.sh >/dev/null 2>&1 & sleep 9; snap 18-lock; pkill -x i3lock; sleep 1
echo DONE > $OUT/done
