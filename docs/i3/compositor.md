---
title: "Compositor (picom)"
parent: "i3 desktop"
nav_order: 7
---

{% raw %}
# Compositor (picom)

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


I run picom so terminals, polybar, Spotlight and notifications can be **translucent with the blurred wallpaper behind them**. Opaque windows are never blurred, shadows and fades are off, and the corner radius is zero except for Spotlight's rounded box.

## Two variants and a symlink

`~/.config/picom/picom.conf` is **not a file**: it is a symlink to one of two real files, and `power-watch.sh` repoints it whenever the power source or the performance mode changes, then sends picom `SIGUSR1` so it reloads:

| File | Used when | What is different |
|---|---|---|
| `picom-ac.conf` | On AC power and the mode is not Quiet | `blur-background = true` with `dual_kawase` strength 6 (everything except the desktop is blurred), `inactive-dim` available |
| `picom-bat.conf` | On battery, or in Quiet mode | **No blur** and no dimming, the GPU stays near idle. One exception: a blur rule that matches *only* Spotlight so its text stays readable while it is open |

Both files share: `backend = "glx"`, `vsync = true`, `use-damage = true` (redraw only what changed), `unredir-if-possible = false`, `shadow = false`, `fading = false`, `corner-radius = 0` with `corner-radius-rules = [ "26:class_g = 'Spotlight'" ]`, `detect-client-opacity = true`, `mark-wmwin-focused`, `mark-ovredir-focused`.
`picom-ac.conf` additionally has `inactive-dim-fixed = true` and `focus-exclude` for Rofi and Polybar.

**Careful when editing:** `sed -i` on a symlink replaces it with a plain file, which silently breaks the AC/battery switch until the next plug event relinks it. Edit `picom-ac.conf` and `picom-bat.conf` themselves.

## What the Settings app changes

Settings → Display → *Effects*: **Blur on AC power** rewrites `blur-background = true|false;` in `picom-ac.conf`, and **Dim inactive windows** rewrites `inactive-dim = 0.10` or `0.0`. After editing it sends picom `SIGUSR1`. Settings never edits the battery variant.

## Why `unredir-if-possible = false`

picom can "unredirect" a fullscreen window: it stops compositing and lets the window go straight to the screen, which saves power for video. The lock screen is a fullscreen window, and I saw it fail to appear after the idle timeout (the old screen stayed up and the lock only showed after I touched the mouse).
I tested that path 12 times in a row with and without unredirect and it painted every time either way, so I cannot prove the setting is *the* fix; I keep it off because it removes one path that is known to leave stale frames. The cost is a little more power while a video is fullscreen.
Two things I tried and **removed**:

- `use-damage = false` made the lock screen reliable too, but turns every change into a full-screen redraw and blur at 2560×1600, and I suspected it of adding lag.
- Sending picom `SIGUSR1` from `lock.sh` to force a repaint **made things worse**: in an A/B run of 8 lock activations it failed to paint 3 times with the poke and 0 times without it.

## Reload, restart, debug

```bash
pkill -USR1 -x picom                        # reload the config (what the scripts do)
picom --config ~/.config/picom/picom.conf   # run it in a terminal to see errors
pgrep -x picom || echo "not running"        # i3 starts it with a plain exec: if it dies it stays dead
```

i3 starts picom with a plain `exec`, so a crash is not restarted. If translucency disappears, run it again as above.

## Performance notes

I measured the compositor with a GL test (`glxgears`) at 90 Hz and it held 90.0 fps; the blur only costs real GPU time while windows change. On battery the no-blur variant keeps the GPU idle.

{% endraw %}
