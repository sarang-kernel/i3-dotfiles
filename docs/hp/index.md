---
title: "HP desktop and server"
nav_order: 8
has_children: true
description: "My HP EliteBook: Hyprland desktop and home server"
---

# The HP: Hyprland desktop and home server

The HP EliteBook 840 G1 (Core i5-4300U, 15 GB RAM, a 2013 laptop) is my **home server**: it serves Jellyfin, Audiobookshelf, Calibre-Web, Immich and a dashboard, mostly over Tailscale, with an external USB drive for media. It is also a normal laptop with a **Hyprland** desktop in the same warm look as the i3 one.

> The HP's configuration lives in `~/.config/hypr` (and `~/.config/quickshell`, `~/.local/share/hp-dash`). Unlike my i3 setup it is **not in a git repository yet**, so this section is generated from the files on the machine itself; the file paths are the real ones.

## Pages

| Page | What you get |
|---|---|
| [Hyprland setup](hyprland.html) | The Lua config files one by one, the session start, the terminals |
| [Keybindings](keybindings.html) | Every bind with its description (generated) |
| [Theming](theming.html) | Wallpaper-driven colours, theme packs, light/dark |
| [Swappable shell](shell.html) | Waybar, Quickshell or DMS: three shells, one desktop |
| [Home server](server.html) | `rice status`, `server.conf`, ambient checks, backups, maintenance mode |
| [hp-dash](hp-dash.html) | My browser control center on port 9100: user guide, security model, API |
| [Boot and server tuning](tuning.html) | `server-tune.sh`, `hp-boot-tune.sh`, the flaky USB drive, the boot pile-up |
| [The `rice` command and tools](tools.html) | The CLI and the script reference |
| [Script reference](script-reference.html) | Every script with its header (generated) |

## At a glance

| | |
|---|---|
| Compositor | Hyprland (Lua config, validated with `Hyprland --verify-config`) |
| Panel | 1600×900, scale 1 |
| Shells | `classic` (waybar + swaync + swayosd), `hypr` (my Quickshell shell), `dms` |
| Terminal | foot server + footclient (about 20 MB for all windows), kitty as the fallback (software GL on this iGPU) |
| Theme | Catppuccin Mocha, or generated from the wallpaper with matugen |
| Network | iwd + systemd-networkd, Tailscale |
| Remote | SSH, hp-dash (browser), optional wayvnc on the Tailscale address only |
