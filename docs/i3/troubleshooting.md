---
title: "Troubleshooting"
parent: "i3 desktop"
nav_order: 13
---

# Troubleshooting

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


Everything here happened to me at least once.

## Super key does nothing / Caps Lock is Super

The config uses `Mod4` as `$mod`. On my laptop Caps Lock is remapped to Super in three places: Xorg's `/etc/X11/xorg.conf.d/00-keyboard.conf` (`XkbOptions "caps:super"`, written by `localectl`), `~/.xprofile` (`setxkbmap -option caps:super`), and the greeter's sway config (`xkb_options caps:super`) so the login screen behaves the same. The old `setxkbmap` lines in `i3/config` are commented out. If Super stops working after a keyboard change, run `setxkbmap -option caps:super` and check with `xev`.

## A script says it is "already running" or two copies run

Every long-running script kills its previous copy through a pid file under `$XDG_RUNTIME_DIR` on start. If a copy survives an i3 restart, check with `pgrep -af 'display-agent|power-watch|nightlight|autocaffeine|autorotate'` and kill the extras; the next reload fixes it.

## The screen did not rotate / rotated wrongly

`autorotate.sh` needs the sensor claim from `iio-sensor-proxy`. If `monitor-sensor` prints *Failed to claim*, the script retries with backoff (2 s doubling to 30 s); `logger -t autorotate` entries in the journal show it. `Super+Shift+O` may have **frozen** rotation: check `~/.local/state/autorotate.lock`. The panel name is `eDP-1` or `eDP-2` depending on which GPU driver registered first; everything looks it up at run time (except `rog-lean-session.sh`'s optional `hz60` part, which hard-codes `eDP-1`).

## The refresh rate "blinks"

Adaptive refresh switches the mode after 60 s of idleness and back on the first key; switching a mode blinks the panel. It only acts from 110 Hz upward, so at 90 Hz on AC it does nothing. If you see blinking, check `ADAPTIVE` and `RATE_AC` in [Settings](../scripts/settings-reference.html). `Settings → Display → Adaptive refresh` turns it off.

## Screen does not lock after the timeout (or locks only when I move the mouse)

See [Lock screen](lock-screen.html) and [Compositor](compositor.html). Quick checks: `xset q | grep -A3 "Screen Saver"` (timeout), `pgrep -a xss-lock`, `pgrep -x picom`.

## No translucency / terminals fully black

picom is not running (`pgrep -x picom`), or `picom.conf` was replaced by a regular file. Fix: `ln -sfn picom-ac.conf ~/.config/picom/picom.conf; pkill -USR1 -x picom` or start picom again.

## Spotlight does not open

`rog-ui.sh restart`, then press `Super+D`. If it still fails, run `python3 ~/.config/scripts/spotlight.py` in a terminal to see the traceback. Spotlight must be started from the desktop session, not over ssh (it hands its environment to everything it launches).

## gedit crashes or hangs on close

gedit 51 segfaults in `libgedit-51.so` on this machine (reproducible with `gedit --standalone`) and spins a CPU core for several seconds on a normal launch. I replaced my quick-notes use with the Neovim scratchpad (`Super+N`).

## The clock is wrong in the bar

The bar shows local time through `internal/date`; `timedatectl` and `/etc/localtime` decide. The restore ISO sets `Asia/Kolkata`.

## Where the logs are

- `journalctl --user -b` for scripts that use `logger` (`autorotate`) and user units (`rog-wallpaper`, the Spotlight alarms).
- `~/.cache/wallpaper-cycle/wallpaper_cycle.log` for the wallpaper script.
- `/tmp/vx-*.log` while making screenshots; `~/lag-notes.log` for lag snapshots.
