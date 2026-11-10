---
title: "Keybindings"
parent: "i3 desktop"
nav_order: 3
description: "Every i3 keybinding, generated from the config"
---

# Keybindings

Every row here is generated from my real `i3/config` (the `bindsym` lines), so this page cannot drift from what the keys really do. `Super` is the Windows key, which on my keyboards is also Caps Lock (see [Troubleshooting](troubleshooting.html)). You do not have to remember any of this: **Super+F1** or **Super+/** opens the same list as a searchable menu ([`keys.sh`](../scripts/session.html#keyssh)).

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


## Launching things

| Key | What it does | Command in the config |
|---|---|---|
| `Super + Enter` | Terminal (the default one) | `i3-sensible-terminal` |
| `Super + t` | kitty terminal | `kitty` |
| `Super + Tab` | Window switcher (rofi) | `rofi -show window` |
| `Super + b` | Show/hide the bar | `polybar-msg cmd toggle` |
| `Super + F1` | Searchable list of every keybinding (rofi) | `~/.config/scripts/keys.sh` |
| `Super + /` | Searchable list of every keybinding (rofi) | `~/.config/scripts/keys.sh` |
| `Super + Shift + Esc` | GUI task monitor | `~/.config/scripts/sysmon.sh` |
| `Super + d` | Spotlight (toggle) | `~/.config/scripts/rog-ui.sh spotlight` |
| `Super + ,` | Settings app | `~/.config/scripts/rog-ui.sh settings` |
| `Super + Shift + v` | Spotlight in clipboard-history mode | `~/.config/scripts/rog-ui.sh clip` |
| `Super + n` | Scratchpad: floating Neovim on ~/Documents/scratch.md (toggle) | `~/.config/scripts/scratch.sh` |


## Windows: focus, move, close

| Key | What it does | Command in the config |
|---|---|---|
| `Super + Shift + q` | Close the window | `kill` |
| `Super + q` | Close the window | `kill` |
| `Super + h` | Focus left | `focus left` |
| `Super + j` | Focus down | `focus down` |
| `Super + k` | Focus up | `focus up` |
| `Super + l` | Focus right | `focus right` |
| `Super + Left` | Focus left | `focus left` |
| `Super + Down` | Focus down | `focus down` |
| `Super + Up` | Focus up | `focus up` |
| `Super + Right` | Focus right | `focus right` |
| `Super + Shift + h` | Move window left | `move left` |
| `Super + Shift + j` | Move window down | `move down` |
| `Super + Shift + k` | Move window up | `move up` |
| `Super + Shift + ;` | Move window right | `move right` |
| `Super + Shift + Left` | Move window left | `move left` |
| `Super + Shift + Down` | Move window down | `move down` |
| `Super + Shift + Up` | Move window up | `move up` |
| `Super + Shift + Right` | Move window right | `move right` |
| `Super + space` | Focus: floating ⇄ tiled | `focus mode_toggle` |
| `Super + a` | Focus the parent container | `focus parent` |


## Windows: layout and size

| Key | What it does | Command in the config |
|---|---|---|
| `Super + v` | Next window opens below (split vertically) | `split v` |
| `Super + f` | Fullscreen | `fullscreen toggle` |
| `Super + s` | Layout: stacked | `layout stacking` |
| `Super + w` | Layout: tabbed | `layout tabbed` |
| `Super + e` | Layout: toggle split direction | `layout toggle split` |
| `Super + Shift + space` | Floating on/off | `floating toggle` |
| `Super + r` | Enter resize mode | `mode "resize"` |
| `Super + Shift + p` | Pin the window (floating, sticky, always visible) or put it back | `~/.config/scripts/pin.sh` |


## Workspaces

| Key | What it does | Command in the config |
|---|---|---|
| `Super + 1` | Go to workspace 1 | `workspace number $ws1` |
| `Super + 2` | Go to workspace 2 | `workspace number $ws2` |
| `Super + 3` | Go to workspace 3 | `workspace number $ws3` |
| `Super + 4` | Go to workspace 4 | `workspace number $ws4` |
| `Super + 5` | Go to workspace 5 | `workspace number $ws5` |
| `Super + 6` | Go to workspace 6 | `workspace number $ws6` |
| `Super + 7` | Go to workspace 7 | `workspace number $ws7` |
| `Super + 8` | Go to workspace 8 | `workspace number $ws8` |
| `Super + 9` | Go to workspace 9 | `workspace number $ws9` |
| `Super + 0` | Go to workspace 10 | `workspace number $ws10` |
| `Super + Shift + 1` | Send the window to workspace 1 | `move container to workspace number $ws1` |
| `Super + Shift + 2` | Send the window to workspace 2 | `move container to workspace number $ws2` |
| `Super + Shift + 3` | Send the window to workspace 3 | `move container to workspace number $ws3` |
| `Super + Shift + 4` | Send the window to workspace 4 | `move container to workspace number $ws4` |
| `Super + Shift + 5` | Send the window to workspace 5 | `move container to workspace number $ws5` |
| `Super + Shift + 6` | Send the window to workspace 6 | `move container to workspace number $ws6` |
| `Super + Shift + 7` | Send the window to workspace 7 | `move container to workspace number $ws7` |
| `Super + Shift + 8` | Send the window to workspace 8 | `move container to workspace number $ws8` |
| `Super + Shift + 9` | Send the window to workspace 9 | `move container to workspace number $ws9` |
| `Super + Shift + 0` | Send the window to workspace 10 | `move container to workspace number $ws10` |
| `Super + Ctrl + h` | Previous workspace | `workspace prev` |
| `Super + Ctrl + l` | Next workspace | `workspace next` |
| `Super + Ctrl + Shift + h` | Send the window to the previous workspace and follow it | `move container to workspace prev; workspace prev` |
| `Super + Ctrl + Shift + l` | Send the window to the next workspace and follow it | `move container to workspace next; workspace next` |


## Screenshots and OCR

| Key | What it does | Command in the config |
|---|---|---|
| `Print` | Screenshot of the whole screen: to the clipboard and ~/Pictures | `~/.config/scripts/shot.sh full` |
| `Insert` | Screenshot of the whole screen: to the clipboard and ~/Pictures | `~/.config/scripts/shot.sh full` |
| `Shift + Print` | Screenshot of a selected area: to the clipboard and ~/Pictures | `~/.config/scripts/shot.sh area` |
| `Shift + Insert` | Screenshot of a selected area: to the clipboard and ~/Pictures | `~/.config/scripts/shot.sh area` |
| `Shift + Delete` | Screenshot of a selected area: to the clipboard and ~/Pictures | `~/.config/scripts/shot.sh area` |
| `Ctrl + Print` | Screenshot of a selected area: clipboard only, no file | `~/.config/scripts/shot.sh area-clip` |
| `Alt + Print` | Screenshot of the focused window | `~/.config/scripts/shot.sh window` |
| `Super + Print` | Select an area; the text in it goes to the clipboard (OCR) | `~/.config/scripts/ocr.sh` |


## Display, power and comfort

| Key | What it does | Command in the config |
|---|---|---|
| `Super + y` | Next wallpaper | `sh -c "$HOME/.config/wallpaper-config/wallpaper-cycle.sh"` |
| `Super + Shift + y` | Previous wallpaper | `sh -c "$HOME/.config/wallpaper-config/wallpaper-cycle-reverse.sh"` |
| `Super + Shift + n` | Night tint on/off | `~/.config/scripts/nightlight.sh toggle` |
| `Super + Alt + n` | Night tint back to the schedule | `~/.config/scripts/nightlight.sh auto` |
| `Super + Shift + o` | Freeze/unfreeze automatic screen rotation | `~/.config/scripts/autorotate.sh lock` |
| `Super + Shift + i` | Caffeine: keep the screen on and unlocked | `~/.config/scripts/caffeine.sh toggle` |
| `Super + Shift + t` | Tablet mode (on-screen keyboard) | `~/.config/scripts/tablet.sh toggle` |
| `Super + Alt + m` | Cycle performance mode Quiet → Balanced → Performance | `~/.config/scripts/power-mode.sh cycle` |


## Hardware keys

| Key | What it does | Command in the config |
|---|---|---|
| `Volume Up` | Volume +5 % | `~/.config/scripts/osd.sh vol up` |
| `Volume Down` | Volume -5 % | `~/.config/scripts/osd.sh vol down` |
| `Mute key` | Mute/unmute the speakers | `~/.config/scripts/osd.sh vol mute` |
| `Mic-mute key` | Mute/unmute the microphone | `~/.config/scripts/osd.sh mic` |
| `Brightness Up` | Brightness +5 % | `~/.config/scripts/osd.sh bri up` |
| `Brightness Down` | Brightness -5 % | `~/.config/scripts/osd.sh bri down` |
| `Keyboard-light Up` | Keyboard backlight on (all states) | `asusctl aura power keyboard --boot --awake --sleep` |
| `Keyboard-light Down` | Keyboard backlight (default) | `asusctl aura power keyboard` |
| `Touchpad key` | Touchpad on/off | `~/.config/i3/toggle-touchpad.sh` |


## Session

| Key | What it does | Command in the config |
|---|---|---|
| `Super + Shift + l` | Lock the screen | `$HOME/.config/i3lock/lock.sh` |
| `Super + Esc` | Power menu | `python3 ~/.config/scripts/power-menu.py` |
| `Super + Shift + c` | Reload the i3 config | `reload` |
| `Super + Shift + r` | Restart i3 in place | `restart` |
| `Super + Shift + e` | Exit i3 (asks first) | `"i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -B 'Yes, exit i3' 'i3-msg exit'"` |
| `Super + Shift + F12` | Lag snapshot: appends to ~/lag-notes.log | `~/.local/bin/lag-now` |


## Resize mode

| Key | What it does | Command in the config |
|---|---|---|
| `h` | Shrink the window's width by 10 px (or 10 %) | `resize shrink width 10 px or 10 ppt` |
| `j` | Grow the window's height by 10 px (or 10 %) | `resize grow height 10 px or 10 ppt` |
| `k` | Shrink the window's height by 10 px (or 10 %) | `resize shrink height 10 px or 10 ppt` |
| `l` | Grow the window's width by 10 px (or 10 %) | `resize grow width 10 px or 10 ppt` |
| `Left` | Shrink the window's width by 10 px (or 10 %) | `resize shrink width 10 px or 10 ppt` |
| `Down` | Grow the window's height by 10 px (or 10 %) | `resize grow height 10 px or 10 ppt` |
| `Up` | Shrink the window's height by 10 px (or 10 %) | `resize shrink height 10 px or 10 ppt` |
| `Right` | Grow the window's width by 10 px (or 10 %) | `resize grow width 10 px or 10 ppt` |
| `Enter` | Leave resize mode | `mode "default"` |
| `Esc` | Leave resize mode | `mode "default"` |
| `Super + r` | Leave resize mode | `mode "default"` |


## Mouse

These come from `floating_modifier` and `tiling_drag` in the config:

| Gesture | What it does |
|---|---|
| Super + left-drag | Move a floating window |
| Super + right-drag | Resize a floating window |
| Drag a window's title bar | Move a tiled window (`tiling_drag modifier titlebar`) |
| Focus follows mouse | The window under the pointer gets focus without a click (`focus_follows_mouse yes`) |


## Counts

105 bindings in total (11 of them in resize mode).
