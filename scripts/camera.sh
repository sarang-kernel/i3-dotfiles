#!/usr/bin/env bash
# rog-tune: polybar camera indicator. The display agent sets the flag while any app has the webcam open; the bar shows a red camera then.
[[ ${1:-bar} == bar ]] || exit 0
[[ -e ${XDG_RUNTIME_DIR:-/tmp}/camera.on ]] && printf '%%{F#e06c5a}%s cam%%{F-}' "$(python3 -c "print(chr(0xf030))")"
