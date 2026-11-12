---
title: "Troubleshooting"
parent: "Spotlight"
nav_order: 12
---

# Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `Super+D` does nothing | The daemon is not running or its FIFO is stale. `rog-ui.sh restart`, then try again. Run `python3 ~/.config/scripts/spotlight.py` in a terminal for the traceback |
| It opens, but launching apps fails | It was started over ssh or before the session had `DISPLAY`/D-Bus. Restart it from a terminal *inside* the desktop |
| File search finds nothing new | `plocate` is stale: `sudo updatedb` |
| A `filetype:` or `.ext` listing is empty | Nothing outside Trash, caches and hidden folders has that extension, or the file index is old (`sudo updatedb`) |
| *Search inside documents* is slow the first time | PDFs are being converted to cached text; later searches are fast |
| Calculator row does not appear | The text did not look like maths, or `qalc` printed an error; try `=` in front |
| Clipboard history is empty after a reboot | It is not: it is on disk. If `~/.local/state/spotlight/clipboard.json` is gone or unreadable it starts empty. A history file that is not valid JSON is ignored (starts empty) |
| An entry I copied is missing | Texts over 500 000 characters and images over 40 MB are skipped; empty or whitespace-only texts too |
| Window thumbnails missing in `w ` | Only windows on the visible workspace can be captured, only the first 8, and `imagemagick` must be installed |
| It looks too transparent / unreadable | Settings → Spotlight → *Transparency*; blur only exists when picom runs |
| Spotlight is blank for a moment | The first frame is hidden on purpose (see [How it works](internals.html#the-window-dance)); a slow compositor makes the delay visible |
| High memory | It restarts itself above 150 MB after it closes; `rog-ui.sh restart` does it by hand |
| The *Settings* window looks unstyled | The two windows share a process; Spotlight's CSS is scoped to `window.spotlight`. If Settings looks wrong, start it fresh (`pkill -f settings.py`) |

Logging: Spotlight prints nothing by default. For a trace run it from a terminal. The resident process's stderr goes to `/dev/null` (`rog-ui.sh` redirects it), so use a terminal run for debugging.
