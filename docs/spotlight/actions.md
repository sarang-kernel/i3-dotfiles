---
title: "Actions"
parent: "Spotlight"
nav_order: 3
---

# Actions

Actions are rows that *do* something instead of opening something. They appear for queries of **two or more characters** that match the title or its keywords; the list below is generated from `action_items()` in `spotlight.py`.
Many call my other scripts (see [Scripts](../scripts/)), so without those scripts the rows are missing or do nothing. Recently used actions float up (frecency, see [How it works](internals.html#ranking)).

| Action shown | Keywords that find it | What it runs |
|---|---|---|
| Lock screen | lock | `lock.sh` |
| Sleep | suspend sleep | `systemctl suspend` |
| Restart | reboot restart | `systemctl reboot` |
| Shut down | poweroff shutdown power off | `systemctl poweroff` |
| Log out | logout exit i3 | `i3-msg exit` |
| Performance mode: Quiet (least battery) | performance mode quiet battery saver silent | `power-mode.sh quiet` |
| Performance mode: Balanced | performance mode balanced normal | `power-mode.sh balanced` |
| Performance mode: Performance (CPU and fans unrestricted) | performance mode fast turbo max | `power-mode.sh performance` |
| Night tint on/off | night light tint warm | `nightlight.sh toggle` |
| Caffeine on/off (keep screen awake) | caffeine awake idle presentation | `caffeine.sh toggle` |
| Tablet mode on/off | tablet keyboard touch | `tablet.sh toggle` |
| Freeze/unfreeze auto-rotate | rotate rotation lock orientation | `autorotate.sh lock` |
| Next wallpaper | wallpaper background | `str(HOME / .config/wallpaper-config/wallpaper-cycle.sh)` |
| Browse all apps | apps all browse show all applications grid | `rog-ui.sh apps` |
| Back up to hp-server… | backup rsync sync server hp external | `rog-ui.sh backup` |
| Settings | settings preferences options configure toggles | `rog-ui.sh settings` |
| System update (reads Arch news first) | update upgrade pacman news arch system packages | `kitty --class rog-sync rog-update.sh` |
| Roll back the last update | rollback roll back undo update downgrade restore packages | `kitty --class rog-sync rog-update.sh --rollback` |
| Task monitor | task monitor processes cpu memory | `sysmon.sh` |
| Keybinds | keys shortcuts keybinds help | `keys.sh` |
| Restart i3 | reload restart i3 | `i3-msg restart` |
| Hibernate | hibernate | `systemctl hibernate` |


Notes:

- **Hibernate** is only offered when the kernel command line contains `resume_offset` (hibernation is set up).
- *System update* and *Roll back the last update* open a floating terminal (class `rog-sync`) running `rog-update.sh` so I can read the Arch news and watch pacman.
- Performance-mode actions change `MODE_AC` or `MODE_BAT` for the power source I am on (see [Power scripts](../scripts/power-display.html#power-modesh)).
