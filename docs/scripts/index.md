---
title: "Scripts"
nav_order: 4
has_children: true
description: "All my desktop scripts, explained"
---

# Scripts

Everything in `~/.config/scripts` (the repo's `scripts/` folder). Nearly all of it started as one big installer, `rog-lean-session.sh`, which writes these files out; today the files are the source of truth and the repo keeps them in sync (see [rog-tune](../rog-tune/)).

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


## Every script


| Script | What it does (first line of its header) | Documented in |
|---|---|---|
| `accent.sh` | apply the accent colour where Spotlight/Settings cannot reach: the bar's active workspace and the focused window's border. | [Power, display and input](power-display.html#accentsh) |
| `alarm.py` | the window a Spotlight timer or reminder shows when it rings. Stays until I dismiss it (Enter / Esc); S snoozes 5 minutes. | [Session helpers](session.html#alarmpy) |
| `autocaffeine.sh` | automatic caffeine. The screen stays on and unlocked while a window is fullscreen on the visible workspace (video, | [Session helpers](session.html#autocaffeinesh) |
| `autorotate.sh` | follow the accelerometer. Panel + touchscreen + pen rotate together. | [Power, display and input](power-display.html#autorotatesh) |
| `caffeine.sh` | caffeine. While on: no auto-lock, no screen blanking (closing the lid still suspends, Super+Shift+L still locks). | [Session helpers](session.html#caffeinesh) |
| `camera.sh` | polybar camera indicator. The display agent sets the flag while any app has the webcam open; the bar shows a red camera then. | [Session helpers](session.html#camerash) |
| `display-agent.py` | Camera in use: inotify on the webcam's device node (no polling); the flag file + a bar ping when it changes. | [Power, display and input](power-display.html#display-agentpy) |
| `input-apply.sh` | apply touchpad / pointer / keyboard settings (at login, on i3 restart, and when Settings changes them) | [Power, display and input](power-display.html#input-applysh) |
| `keys.sh` | show every i3 keybind in a searchable rofi list (type to filter, Esc to close) | [Session helpers](session.html#keyssh) |
| `lag-now` | lag-now: press the key when the machine lags. It takes a one-second snapshot of what the machine is doing and what the kernel | [Session helpers](session.html#lag-now) |
| `login-apply.sh` | things that happen once per login (not on every i3 restart) | [Session helpers](session.html#login-applysh) |
| `login-bg.sh` | wallpaper hooks: keeps the login screen's wallpaper equal to the desktop wallpaper (the greeter runs as another user | [System, backup and update tools](system.html#login-bgsh) |
| `nightlight.sh` | night tint through the display's gamma ramp (no extra packages, no popups). | [Power, display and input](power-display.html#nightlightsh) |
| `ocr.sh` | select an area on screen, put the text in it on the clipboard (needs tesseract + tesseract-data-eng) | [Session helpers](session.html#ocrsh) |
| `osd.sh` | volume / mic / brightness actions. Silent: no bars, no popups (the bar shows the state). | [Session helpers](session.html#osdsh) |
| `pen-setup.sh` | pen-setup: map the ASUS stylus and touchscreen to the internal panel (run once at login by i3). | [Session helpers](session.html#pen-setupsh) |
| `pin.sh` | pin the focused window (floating + sticky), or put it back | [Session helpers](session.html#pinsh) |
| `power-menu.py` | power menu (Super+Escape). One row of big tiles: Lock, Log out, Sleep, Hibernate, Restart, Shut down. | [Session helpers](session.html#power-menupy) |
| `power-mode.sh` | performance mode for the power source I am on right now (saved, so it is also what plug/unplug restores) | [Power, display and input](power-display.html#power-modesh) |
| `power-watch.sh` | power-aware behaviour, event driven (upower). Re-applied on every plug/unplug. | [Power, display and input](power-display.html#power-watchsh) |
| `rg-pre.sh` | ripgrep --pre helper for Spotlight's deep search: PDF text is extracted once and cached (by path + mtime) | [System, backup and update tools](system.html#rg-presh) |
| `rog-ui.sh` | client for the resident Spotlight/Settings process (it starts at login, so opening is near-instant). | [System, backup and update tools](system.html#rog-uish) |
| `rog-update.sh` | update the system the careful way: show the Arch news since my last update first, then (if I agree) run pacman -Syu. | [System, backup and update tools](system.html#rog-updatesh) |
| `scratch.sh` | scratch: my notepad. One persistent file (~/Documents/scratch.md) in a floating Neovim window that autosaves as I type, so there is | [Session helpers](session.html#scratchsh) |
| `settings.py` | (title, value, subtitle) rows describing the battery right now. | [Settings app](settings-app.html) |
| `shot.sh` | screenshot → clipboard (PNG, pastes into browsers/chat/editors) + ~/Pictures. Silent. | [Session helpers](session.html#shotsh) |
| `spotlight.py` | Resident mode: Spotlight is built once and shown on request (~instant); commands arrive on a FIFO. (Settings is NOT kept in memory.) | [Spotlight](../spotlight/) |
| `sync-server.sh` | manual backup of my research to hp-server (rsync over SSH). Runs only when I ask; never deletes anything there. | [System, backup and update tools](system.html#sync-serversh) |
| `sysmon.sh` | open a GUI task monitor: per-process CPU/RAM/disk/GPU, per-app grouping | [Session helpers](session.html#sysmonsh) |
| `tablet.sh` | tablet mode = an on-screen keyboard (onboard) docked at the bottom that appears when a text field gets focus. | [Session helpers](session.html#tabletsh) |
| `vaapi-check.sh` | is hardware video decoding available? Needs libva-utils (sudo pacman -S libva-utils). Read-only. | [System, backup and update tools](system.html#vaapi-checksh) |
| `wallpaper-timer.sh` | (re)create the timer that changes the wallpaper every WALL_EVERY minutes (0 = never; set in Settings -> Wallpaper) | [Power, display and input](power-display.html#wallpaper-timersh) |


## Other scripts that are documented elsewhere

| Where | What |
|---|---|
| `i3/toggle-touchpad.sh` | [Session helpers](session.html#toggle-touchpadsh) |
| `wallpaper-config/wallpaper-cycle*.sh` | [System tools](system.html#wallpaper-cyclesh) |
| `polybar/scripts/*.sh` | [Polybar](../i3/polybar.html) |
| `rofi/*.sh`, `rofi/spotlight-v3.py` | the old rofi launcher, kept for reference: [Other app configs](../i3/other-apps.html) |
| `rog-tune/*.sh` | [rog-tune](../rog-tune/) |
| `iso/*` | [Restore ISO](../iso/) |
| `docs/make-screenshots/*` | [How the screenshots are made](../i3/screenshots.html) |
