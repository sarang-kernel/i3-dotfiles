#!/usr/bin/env bash
pkill -f "Xvfb :99" 2>/dev/null; sleep 0.5
rm -rf /tmp/vx-run /tmp/vx-state; mkdir -m700 /tmp/vx-run /tmp/vx-state
export DISPLAY=:99 XDG_RUNTIME_DIR=/tmp/vx-run XDG_STATE_HOME=/tmp/vx-state
Xvfb :99 -screen 0 2560x1600x24 -nolisten tcp -ac >/tmp/vx-xvfb.log 2>&1 &
sleep 1.5
setsid dbus-run-session -- bash ~/shots/vx/inner.sh >/tmp/vx-inner.log 2>&1 </dev/null &
sleep 6
echo started
