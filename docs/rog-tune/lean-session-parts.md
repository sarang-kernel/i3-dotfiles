---
title: "rog-lean-session.sh parts"
parent: "rog-tune"
nav_order: 2
---

# `rog-lean-session.sh`: the user-side parts

`rog-lean-session.sh` is the **user-side** sibling: no sudo, it edits files in my home folder (`i3/config`, `polybar/config.ini`, `kitty.conf`, `.bashrc`, autostart entries) and **writes out the helper scripts** that live in `~/.config/scripts`. Almost every feature of the desktop was added as one of its parts.

```text
Session-side trimming + quality of life for rog (no sudo). Dry run by default; --undo restores everything it touched.
  ~/rog-tune/rog-lean-session.sh [parts…]          show what would change
  ~/rog-tune/rog-lean-session.sh --apply [parts…]  do it
  ~/rog-tune/rog-lean-session.sh --undo            restore i3 config, polybar, kitty, .bashrc, autostart files
parts (default: all except vaapi)
```

It follows the same discipline as `rog-tune.sh`: dry run by default, `--apply` to change things, `--undo` to restore. Before changing a file it copies it to `~/.local/share/rog-tune/<name>.before`; lines it adds are tagged with the marker `rog-tune` (that is why so many comments in my configs start with `# rog-tune:`), so a part can find its own lines and a second run does not duplicate them. `created.list` remembers files it created so `--undo` can remove them.

Two things to know:

- The scripts are **embedded** in this installer as here-documents (that is why it is 4000+ lines long). The repo's `scripts/` copies are the live files; `embsync.py` in the ISO tooling keeps the embedded copies and the live ones in step. If you edit a live script, remember the installer would write the older embedded copy next time it runs that part.
- Parts that are left out of `ALL` (the default) need an explicit request: `picom`, `hz60`, `vaapi`, `psd` (profile-sync-daemon, costs about 2 GB of RAM) and a few retired ones.

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


## The 34 parts


### `automount`

disable the broken user unit home-sarang-mnt-server.automount (fails at every login)


### `picom`

stop starting picom (i3 line AND /etc/xdg/autostart/picom.desktop, which dex would start anyway). My picom.conf draws nothing (no shadows/fades/transparency) yet costs ~4 % of a core at 165 Hz. Cost: possible tearing


### `compositor`

lean picom (explicit config: no shadows/fades/blur, damage tracking, unredirects fullscreen) so terminals, polybar and notifications can be translucent. Replaces the old 'picom' (= turn the compositor off) part


### `hz60`

60 Hz at every login (the panel only offers 165 and 60)


### `autostart`

stop launching nm-applet (NetworkManager is disabled; iwd does Wi-Fi), the GNOME disk-notify daemon and the AT-SPI accessibility bus at login (apps start AT-SPI themselves when needed)


### `bash`

lazy-load nvm in .bashrc: a new shell takes ~0.42 s today, ~0.1 s after (node 24 stays on PATH)


### `kitty`

snappier terminal: repaint_delay 6, input_delay 1, no bell


### `xset`

faster key repeat (250 ms delay, 50/s) and no X bell. Needs xorg-xset (it was not installed, so this did nothing until now)


### `polybar`

stop polling: the mic indicator follows pulse events instead of spawning 2 processes every second; brightness 1→3 s, clock 1→5 s, cpu/memory 2→3 s


### `shot`

screenshots go to the CLIPBOARD (paste straight into chat/docs) and to ~/Pictures, with a notification: Print / Insert        whole screen       Shift+Print / Shift+Insert / Shift+Delete   select an area Ctrl+Print            area, clipboard only (no file)         Alt+Print   focused window


### `osd`

volume / mic / brightness keys show an on-screen bar (dunst); volume steps 5 % instead of 10 %


### `ui`

a consistent Catppuccin look at zero runtime cost (no compositor needed): i3 gaps, 2 px borders instead of title bars, coloured focus; polybar icons instead of "VOL/BAT/CPU" text, wider spacing, no "|" separators; kitty's theme (kitty.conf includes a theme.conf that is entirely commented out, hence the plain black terminals); a dunst config (none exists, so notifications use dunst's defaults); dark GTK apps with Papirus-Dark icons


### `quiet`

no on-screen bars, no notifications (the notification daemon is parked), silent screenshots; brightness shown in the bar


### `keys`

Super+F1 (or Super+/) opens a searchable menu of every i3 keybind


### `focus`

macOS-style centred clock, focus FOLLOWS the mouse (kept), vim-style resize, Super+Ctrl+H/L between workspaces


### `power`

on AC: blur + 90 Hz. On battery: no blur, 60 Hz. Switches by itself when I plug/unplug (event driven, no polling)


### `loginbg`

keeps the login screen's wallpaper in step with the desktop wallpaper


### `lock`

the lock screen shows my current wallpaper, blurred and darkened (the old script passed a JPEG to i3lock, which only reads PNG, and read ~/.fehbg, which my wallpaper script never updates)


### `idle`

lock + screen off by power source (AC: 10 / 15 min, battery: 2 / 3 min) and lock before suspend (xss-lock)


### `ocr`

Super+Print: select an area, its text lands on the clipboard (tesseract)


### `night`

Super+Shift+N toggles a warm night tint (~4000 K, display gamma, no daemon); Super+Alt+N returns to the schedule (on 19:00-07:00, like my wallpapers). Survives mode switches


### `sysmon`

clicking CPU or RAM in the bar, or Super+Shift+Esc, opens a proper GUI task monitor (Mission Center; falls back to Resources, GNOME System Monitor, then btop)


### `psd`

browser profiles (Chrome, Firefox) live in RAM and sync back to disk: much snappier browsers. Costs ~2 GB of RAM


### `rotate`

the session's auto-rotate: panel, touchscreen and pen follow the accelerometer from the moment I log in (my script only reacted to later changes, skipped the pen and started a new copy at every i3 restart). Super+Shift+O freezes it


### `spotlight`

Super+D: a real Spotlight. Searches AS YOU TYPE: apps (most-used first), open windows, files (plocate), maths and unit conversion (qalc), clipboard history (c ...), commands (> ...), system actions (lock, sleep, night tint ...). Vim keys


### `settings`

Super+comma (or Spotlight: "settings"): one window for everything I can toggle or fiddle with (night tint, lock timers, battery profile, blur, focus-follows-mouse, rotation, tablet mode, Spotlight, backup). Applies immediately


### `caffeine`

Super+Shift+I keeps the screen on and unlocked; (nothing is shown in the bar). It also switches on BY ITSELF while a window is fullscreen or an app uses the microphone (video, calls); music does not count


### `tablet`

Super+Shift+T toggles tablet mode (OFF by default): an on-screen keyboard that pops up when I touch a text field. Needs onboard


### `pin`

Super+Shift+P: float the window, keep it above everything and on every workspace (press again to tile it back)


### `input`

touchpad (tap, natural scrolling, palm rejection), pointer speed, key repeat and starting with the mic muted, all from Settings


### `barfont`

workspace numbers in a lighter font, and a compact box around the active workspace; weight, size and box/line are in Settings


### `mode`

(part of power) Super+Alt+M cycles Quiet / Balanced / Performance; default Balanced on AC, Quiet on battery


### `display`

adaptive refresh (after a while without input the panel drops to the idle rate, any key or touch brings the full rate back, no polling) and cinema mode (a fullscreen video player gets a rate that divides the film's frame rate, 71.928 Hz for 23.976 fps)


### `vaapi`

(opt-in) GPU video decoding in Chrome/Firefox/Zen, so video stops burning CPU. Unverified on this machine


## Undo

`~/rog-tune/rog-lean-session.sh --undo` restores i3 config, polybar, kitty, `.bashrc`, picom config, rofi themes, wallpaper scripts and the lock script from the `.before` copies, deletes the autostart stubs it made, removes the lines it added to Firefox/Zen `user.js`, disables `psd` and `dunst` masking if it did those, and re-enables the broken automount if it had disabled it. Then log out and in (or `i3-msg restart`).
