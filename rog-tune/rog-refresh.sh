#!/usr/bin/env bash
# The panel runs at 165 Hz; most desktop work looks the same at 60 and costs much less (compositor, GPU, heat, fans).
#   ~/rog-tune/rog-refresh.sh            show the modes
#   ~/rog-tune/rog-refresh.sh 60|120|165 switch now (undone at next login unless you add it to your i3 config)
export DISPLAY=${DISPLAY:-:0}
out=$(xrandr --query | awk '/ connected primary| connected/ {print $1; exit}')
case "${1:-}" in
60 | 120 | 165) xrandr --output "$out" --rate "$1" && echo "$out → $1 Hz" ;;
*) xrandr --query | sed -n '/^'"$out"'/,/^[A-Z]/p' | head -n 6 ;;
esac
