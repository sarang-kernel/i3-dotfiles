#!/usr/bin/env bash
# rog-tune: open a GUI task monitor: per-process CPU/RAM/disk/GPU, per-app grouping
for c in missioncenter resources gnome-system-monitor; do command -v "$c" >/dev/null && exec "$c"; done
exec kitty --class sysmon -e btop
