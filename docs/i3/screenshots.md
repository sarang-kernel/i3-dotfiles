---
title: "How the screenshots are made"
parent: "i3 desktop"
nav_order: 12
---

# How the screenshots are made

The pictures in the READMEs were taken on a **throwaway virtual screen**, not on my real desktop, so none of my real windows (or my Wi-Fi name in the bar) end up in them. The tooling is in `docs/make-screenshots/` of the repo.

## The idea

`Xvfb :99` is an invisible X server. A second copy of my configs runs inside it: the real i3 config with every autostart line stripped (so nothing touches the real session), a polybar config without the Wi-Fi module, and a separate Spotlight process with its own runtime and state directories (so my real clipboard history is not read or written). `xdotool` types into it and `import` or `ffmpeg x11grab` captures it.

## The steps

| Script | What it does |
|---|---|
| `prep.sh` | Builds the three throwaway configs (`i3.conf`, `polybar.ini`) under `~/shots/vx` and copies the scripts there |
| `start.sh` | Starts Xvfb at 2560×1600 with a private `XDG_RUNTIME_DIR` and `XDG_STATE_HOME`, then runs i3 and Spotlight inside a private D-Bus session (`inner.sh`) |
| `scene.sh` | Opens kitty windows (Neovim, fastfetch, a git log), then drives Spotlight with `xdotool` through apps, maths, units, emoji, timers, clipboard, files, preview, actions, commands, windows and all-apps; then the power menu, the Settings app tiled in, tabbed and stacked layouts and the lock screen. Writes `out/*.png` |
| `demo.sh` | Records the same session to `demo.mp4` and converts it to a small GIF |

Requirements: `xorg-server-xvfb`, `xdotool`, `ffmpeg`, `imagemagick`, `kitty`, `fastfetch`.

## Lessons (so I do not relearn them)

- **No compositor in the virtual screen.** With picom running under software GL, terminal windows came out blank, so Spotlight looks solid dark in the pictures. The real thing is translucent.
- **It is slow** (software rendering). `scene.sh` takes about seven minutes; short waits give half-drawn frames, so the script waits generously after each keystroke burst.
- **Never screenshot the real screen for a public repo.** The first attempt did, and caught private windows. Every picture is looked at before it is committed.
- **Escape twice** after each scenario: Spotlight's preview and all-apps modes eat the first Escape, and a leftover open Spotlight swallows the next scenario's typing.
