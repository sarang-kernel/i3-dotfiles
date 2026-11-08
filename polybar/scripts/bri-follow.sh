#!/usr/bin/env bash
# rog-tune: polybar brightness indicator. No polling processes: reads sysfs with shell builtins and waits on a private fifo.
d=/sys/class/backlight/nvidia_wmi_ec_backlight; [[ -d $d ]] || d=$(ls -d /sys/class/backlight/* | head -n1)
read -r max <"$d/max_brightness"
f=$(mktemp -u); mkfifo "$f"; exec 3<>"$f"; rm -f "$f"
last=
while :; do
	read -r v <"$d/brightness"
	[[ $v != "$last" ]] && { echo "  $((v * 100 / max))%"; last=$v; }
	read -r -t 0.4 -u 3 _ || true
done
