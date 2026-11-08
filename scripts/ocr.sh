#!/usr/bin/env bash
# rog-tune: select an area on screen, put the text in it on the clipboard (needs tesseract + tesseract-data-eng)
command -v tesseract >/dev/null || exit 1
f=$(mktemp "${XDG_RUNTIME_DIR:-/tmp}/ocr.XXXXXX.png"); trap 'rm -f "$f"' EXIT
scrot -o -s "$f" 2>/dev/null && [[ -s $f ]] || exit 0
tesseract "$f" - -l eng --psm 6 2>/dev/null | sed -e 's/[[:space:]]*$//' | xclip -selection clipboard
