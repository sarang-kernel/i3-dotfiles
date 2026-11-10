---
title: "Script reference"
parent: "HP desktop and server"
nav_order: 10
---

# Script reference (HP)

Every script that is part of the HP desktop and server tooling, with the first line of its own header comment. All of them live in `~/.config/hypr/`.

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


## Scripts


| File | What it does (from its header) | Lines |
|---|---|---|
| `scripts/ambient.sh` | Session timer (started by autostart): changes the wallpaper every N minutes when the settings hub's | 88 |
| `scripts/caffeine.sh` | caffeine.sh [toggle\|status] — hold a systemd idle inhibitor (hypridle respects it), | 25 |
| `scripts/clipboard.sh` | Clipboard history (cliphist) with image thumbnails. | 34 |
| `scripts/colorpicker.sh` | Pick a colour anywhere on screen; copies "#rrggbb" to the clipboard. | 7 |
| `scripts/eco.sh` | eco.sh toggle\|on\|off\|auto-on\|auto-off\|status | 38 |
| `scripts/grayscale.sh` | Grayscale the whole screen with a Hyprland screen shader | 14 |
| `scripts/keybinds.sh` | Cheat-sheet of every bind that has a description, straight from the running compositor. | 19 |
| `scripts/kitty.sh` | kitty launcher. On this Haswell iGPU Hyprland advertises no ARGB8888 dmabuf format, so kitty's | 8 |
| `scripts/launcher.sh` | launcher.sh spotlight\|drun\|calc\|emoji [extra rofi args] | 34 |
| `scripts/lid.sh` | lid.sh close\|open | 17 |
| `scripts/look-toggle.sh` | look-toggle.sh <key> <value>: flip one of the desktop-look presets (conf/user.lua) on and off from a key. | 10 |
| `scripts/maintenance.sh` | Maintenance mode: while you are working on the server, don't alert about the things you are knowingly breaking. | 19 |
| `scripts/nightlight.sh` | nightlight.sh [toggle\|status] | 31 |
| `scripts/osd.sh` | osd.sh vol up\|down\|mute · mic mute · bright up\|down | 36 |
| `scripts/portals.sh` | xdg-desktop-portal is socket/D-Bus activated at login, before Hyprland sets XDG_CURRENT_DESKTOP, so it | 7 |
| `scripts/power-watch.sh` | Enables eco mode when the charger is unplugged and disables it again on plug-in. | 25 |
| `scripts/powermenu.sh` | Power menu — port of ~/.config/rofi/powermenu.sh for Hyprland. | 26 |
| `scripts/record.sh` | record.sh full\|region\|status   — toggles a wf-recorder session. | 42 |
| `scripts/reload.sh` | Validate the config with the real parser first; only reload when it is clean, | 12 |
| `scripts/remind.sh` | Reminders that cost nothing while they wait: each one is a transient systemd user timer. | 49 |
| `scripts/restart-shell.sh` | Restart the shell pieces without touching your windows: bar, notifications, OSD, wallpaper. | 12 |
| `scripts/rice` | The rice and the server from any terminal, including over SSH (finds the running Hyprland session by itself). | 57 |
| `scripts/rice-fix.sh` | rice doctor: checks the rice and the server for known problems; --fix repairs the ones that are safe to repair. | 77 |
| `scripts/rice-meter.py` | What the rice itself costs (not your apps): RAM as PSS (shared pages split fairly) and CPU since the last | 115 |
| `scripts/rice-snapshot.sh` | Snapshots of the rice's own configuration (not your data): a compressed copy of the config directories it manages. | 69 |
| `scripts/rice-update.sh` | System update with a safety net and a readable aftermath. | 74 |
| `scripts/screenshot.sh` | screenshot.sh full\|region\|window\|annotate\|ocr\|qr   (ocr: text of a region → clipboard; qr: decode a code) | 66 |
| `scripts/server-status.py` | From the root jobs (rice-health): backup readability and drive health. | 268 |
| `scripts/settings.sh` | Settings hub (Super+I): appearance, desktop look, wallpaper, power and system in one rofi menu tree. | 244 |
| `scripts/shell.sh` | The desktop shell is swappable; the compositor, windows and theme don't change. | 113 |
| `scripts/term.sh` | Terminal launcher: foot server + footclient when foot is installed (one ~20 MB process for every window, | 31 |
| `scripts/theme-init.sh` | Apply GTK / icon / cursor / font settings through gsettings at session start | 19 |
| `scripts/touchpad-toggle.sh` | Enable/disable the touchpad (replaces ~/.config/i3/toggle-touchpad.sh). | 16 |
| `scripts/tui.sh` | tui.sh <command...> — run a TUI in a floating popup terminal (class tui-popup, see conf/rules.lua). | 8 |
| `scripts/vnc.sh` | Remote desktop over Tailscale only (wayvnc), started on demand so it costs nothing while off. | 35 |
| `scripts/wallpaper.sh` | wallpaper.sh init\|next\|prev\|random\|pick\|set <file>\|list | 129 |
| `scripts/webapp.sh` | Open a site in its own window, like an app. The list lives in webapps.conf, one "name\|url" per line. | 21 |
| `scripts/window-switcher.sh` | Window switcher. rofi's built-in `window` mode can't see Wayland toplevels, | 30 |
| `scripts/zen.sh` | Zen mode (Super+Z): no bar, no gaps/borders/rounding, notifications held back (do-not-disturb). | 16 |
| `system/build-boot-theme.py` | Approximate render of the menu, for checking the design without rebooting. | 203 |
| `system/rice-health.py` | None when the file is sound, otherwise why not. | 126 |
| `system/server-tune.sh` | Home-server fixes that need root. Restarts none of your services. | 280 |
| `system/ssh-lan.sh` | Only let SSH in from your home network, Tailscale and this machine, so the port is closed to the rest of the internet | 102 |
| `system/sudo-window.sh` | A time-limited passwordless sudo, for when you want an assistant (or yourself) to do root work without a prompt each time. | 38 |
| `system/system-rice.sh` | Boot-level rice: console font, Linux console colours from the first kernel message, a GRUB theme generated | 208 |
| `theme/theme.sh` | Wallpaper-driven theming. One palette -> Hyprland, waybar, swaync, swayosd, rofi, hyprlock, kitty, GTK, Qt, | 169 |
| `theme/packs.py` | Named theme packs (the real palettes of well-known schemes, mapped onto the Catppuccin role names every template uses). | 62 |
| `theme/render.py` | Most colourful of matugen's extracted source colours, weighted by how much of the image it covers. | 334 |
| `shell/colors.sh` | Generated by ~/.config/hypr/theme/theme.sh — sourced by ~/.config/hypr/shell/rice.bash. Do not edit. | 18 |
| `shell/rice-completion.bash` | Tab completion for the rice CLI (sourced by rice.bash) | 17 |
| `shell/rice.bash` | Shell layer of the rice, sourced from ~/.bashrc. Colours come from the wallpaper palette | 45 |
| `shell/vt-palette.sh` | Generated by ~/.config/hypr/theme/theme.sh — Linux console (VT) palette, always from the dark palette. | 5 |
| `doctor.sh` | Checks the dependencies and validates the Hyprland config |  |
| `install.sh` | One `sudo pacman -S --needed …` of the official packages |  |
| `report.sh` | Collects versions, config errors, logs and which shell components are up into one file in `~/.cache/hypr/` |  |
