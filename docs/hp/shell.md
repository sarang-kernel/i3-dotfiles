---
title: "Swappable shell"
parent: "HP desktop and server"
nav_order: 5
---

# Swappable shell

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


The compositor, windows and theme never change; only the bar, notifications and on-screen display do. Switch with `Super+I → Shell`, or `scripts/shell.sh use classic|hypr|dms`. It is remembered across logins; anything not installed falls back to `classic`.

| Profile | What runs | Measured here |
|---|---|---|
| `classic` | waybar, swaync, swayosd | about 106 MiB |
| `hypr` | **one Quickshell process** (`~/.config/quickshell/hypr`) | about 130 MiB, 0.04 % CPU idle |
| `dms` | Dank Material Shell (`dms run`) | about 484 MiB |

## `shell.sh`

```text
shell.sh use classic|hypr|dms     switch now and remember it
shell.sh start | stop | status | profile
shell.sh dashboard | overview | launcher | wallpapers | power | notif | dnd [on|off|toggle] | refresh | theme   routed to the running shell
```

It also works from an ssh or tty shell: it finds the running session itself.

## What the `hypr` shell adds

- **Clickable workspaces** (the classic bar cannot do that under a Lua config).
- `Super+A` **dashboard**, `Super+O` **overview** (drag windows between workspaces), `Super+D` **launcher** (apps, open windows, actions, `2+2`, `?search`, `>command`).
- Panels are built on open and freed on close.

Qt's **software renderer is deliberate**: on this GPU GL surfaces lose their alpha (the same cause as the kitty crash) and the software path takes less memory. The cost is no live window thumbnails; the overview shows a one-shot capture of the current workspace and icon + title cards for the rest.

## Warnings

- **Never run `dms setup` or `caelestia install`**: they replace `hyprland.lua`. `dms run` alone only adds `hypr/dms/` and colour files, and picks its own colours from its own wallpaper.
- If the shell crashes, `ambient.sh` restarts it within a minute; after three failed restarts it falls back to `classic`.

## The resource budget (10 %)

The rice measures itself: `scripts/rice-meter.py` sums **PSS memory** and CPU of the shell processes only (not your apps) as a share of the machine (`rice meter`, also the bar's stats drawer). `ambient.sh` governs it: more than 10 % CPU for 3 minutes drops the GPU-heavy effects (eco mode, reason *governor*), and 10 calm minutes restore them. Everything added since is either a native compositor rule (smart gaps, workspace hue ring, zen mode) or a static shader (GPU only, no time uniform), so nothing forces extra frames.
