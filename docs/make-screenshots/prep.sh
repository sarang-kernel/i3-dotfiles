#!/usr/bin/env bash
# Builds the three throwaway configs the virtual screen needs, from my real ones: an i3 config with every autostart line removed (so
# nothing touches the real session), a bar without the Wi-Fi module (it shows my network name), and a compositor-free setup.
set -euo pipefail
mkdir -p ~/shots/vx && cd ~/shots/vx
grep -vE "^[[:space:]]*(exec|exec_always)[[:space:]]" ~/.config/i3/config > i3.conf
sed -E "s/ network( |$)/ /" ~/.config/polybar/config.ini > polybar.ini
cp "$(dirname "$0")"/{env.sh,start.sh,inner.sh,scene.sh,demo.sh} .
chmod +x *.sh
echo "ready: ~/shots/vx/scene.sh (screenshots into out/), then ~/shots/vx/demo.sh (demo.mp4 + demo.gif)"
