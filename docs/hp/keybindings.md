---
title: "Keybindings"
parent: "HP desktop and server"
nav_order: 3
---

# Keybindings (Hyprland on the HP)

The Hyprland setup is written in Hyprland's **Lua config** (0.55 and newer). This table is generated from `conf/binds.lua`: every `bind(...)` with its description. The same descriptions feed the live cheat-sheet (`Super+F1` or `Super+K`, `scripts/keybinds.sh`). Super is **Caps Lock** on this laptop (remapped), so everything is one hand-width away.

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


## Apps & launchers

| Key | What it does |
|---|---|
| `Super + Enter` | Terminal |
| `Super + T` | Terminal |
| `Super + Shift + Enter` | File manager |
| `Super + B` | Browser |
| `Super + D` | Spotlight launcher (apps · files · math · web) |
| `Super + Shift + D` | Application grid |
| `Super + Tab` | Window switcher |
| `Super + Shift + V` | Clipboard history |
| `Super + /` | Emoji picker |
| `Super + Shift + F12` | Lag snapshot (writes ~/lag-notes.log) |
| `Super + Shift + /` | Calculator |
| `Super + C` | Colour picker (copies hex) |
| `Super + F1` | This cheat-sheet |
| `Super + K` | This cheat-sheet |
| `Super + Backspace` | Window transparency toggle |
| `Super + Shift + Backspace` | Gaps off toggle |
| `Super + Ctrl + R` | Set a reminder (10m text · 18:30 text) |
| `Super + Ctrl + Alt + R` | List reminders |
| `Super + Alt + B` | Web apps (Jellyfin, Immich, …) |
| `Super + Alt + N` | Act on the latest notification |
| `Super + Ctrl + N` | Dismiss the latest notification |
| `Super + N` | Notification centre |
| `Super + Shift + N` | Do-not-disturb toggle |
| `Super + A` | Dashboard (Quickshell/DMS shells) |
| `Super + O` | Workspace overview (Quickshell shell) |
| `Alt + Tab` | (no description) |


## Session

| Key | What it does |
|---|---|
| `Super + Esc` | Power menu |
| `Super + Shift + E` | Power menu |
| `Super + Shift + L` | Lock screen |
| `Super + Shift + C` | Reload Hyprland config (with validation) |
| `Super + Shift + R` | Restart bar / notifications / wallpaper |
| `Super + Shift + G` | Grayscale toggle |
| `Super + Y` | Next wallpaper |
| `Super + Shift + Y` | Previous wallpaper |
| `Super + Ctrl + Y` | Wallpaper picker |
| `Super + I` | Settings |
| `Super + Z` | Zen mode (no bar, gaps, borders; DND) |
| `Super + Alt + Y` | Appearance (colours · light/dark · accent) |
| `Super + Alt + Shift + Y` | Toggle wallpaper colours ⇄ Catppuccin |
| `Super + F2` | Battery-saver mode (no blur/animations) |
| `Super + F3` | Night-light toggle |
| `Super + F4` | Keep awake (inhibit idle/lock) |
| `Super + F9` | Touchpad toggle |
| `XF86TouchpadToggle` | Touchpad toggle |


## Windows

| Key | What it does |
|---|---|
| `Super + Q` | Close window |
| `Super + Shift + Q` | Close window |
| `Super + Ctrl + Q` | Force-kill window (SIGKILL) |
| `Super + F` | Fullscreen |
| `Super + Ctrl + F` | Maximise (keep gaps/bar) |
| `Super + Shift + Space` | Toggle floating |
| `Super + P` | Pseudo-tile |
| `Super + E` | Toggle split direction (dwindle) |
| `Super + V` | Next window opens below |
| `Super + Ctrl + V` | Next window opens right |
| `Super + W` | Group (tabbed) toggle |
| `Super + Shift + W` | Pull window out of group |
| `Super + ]` | Next tab in group |
| `Super + [` | Previous tab in group |
| `Super + Space` | (no description) |
| `Super + Alt + Space` | (no description) |
| `Super + Shift + H` | Move window left |
| `Super + Shift + J` | Move window down |
| `Super + Shift + K` | Move window up |
| `Super + Shift + ;` | Move window right |
| `Super + .` | Scroll tape → (scrolling layout) |
| `Super + ,` | Scroll tape ← (scrolling layout) |
| `Super + Shift + .` | Swap column right (scrolling layout) |
| `Super + Shift + ,` | Swap column left (scrolling layout) |
| `Super + -` | Shrink window / column |
| `Super + =` | Grow window / column |
| `Super + H J K L, Super + arrows` | Focus left, down, up, right |
| `Super + Shift + arrows` | Move the window |


## Resize mode (Super+R)

| Key | What it does |
|---|---|
| `Super + R` | Resize mode (hjkl / arrows, Esc to leave) |


## Workspaces

| Key | What it does |
|---|---|
| `Super + Ctrl + left` | Previous workspace |
| `Super + Ctrl + right` | Next workspace |
| `Super + Ctrl + H` | (no description) |
| `Super + Ctrl + L` | (no description) |
| `Super + Ctrl + Shift + left` | Send window to previous workspace |
| `Super + Ctrl + Shift + right` | Send window to next workspace |
| `Super + S` | Scratchpad |
| `Super + Shift + S` | Send window to scratchpad |
| `Super + `` | (no description) |
| `Super + 1 … 0` | Go to workspace 1-10 (0 is workspace 10) |
| `Super + Shift + 1 … 0` | Send the window to that workspace |
| `Super + Alt + 1 … 0` | Send the window there without following it (silently) |
| `Super + Ctrl + H / L` | Previous / next workspace (same as Ctrl + Left/Right) |


## Screenshots & recording

| Key | What it does |
|---|---|
| `Print` | Screenshot: full screen |
| `Shift + Print` | Screenshot: region |
| `Ctrl + Print` | Screenshot: window |
| `Alt + Print` | Screenshot: region → annotate (satty) |
| `Super + Ctrl + Print` | Copy the text in a region (OCR) |
| `Super + Alt + Print` | Decode a QR code in a region |
| `Super + Print` | Screen recording: toggle (full) |
| `Super + Shift + Print` | Screen recording: toggle (region) |


## Mouse

| Key | What it does |
|---|---|
| `Super + left-drag / right-drag` | Move / resize a floating window |
| `Super + scroll` | Next / previous workspace |


## Resize mode

| Key | What it does |
|---|---|
| `H J K L or arrows` | Resize the window by 30 px per press (key repeats); Enter, Esc or Super+R leave |


## Media keys

| Key | What it does |
|---|---|
| `Volume Up/Down/Mute, Mic mute, Brightness Up/Down` | Through `osd.sh` (swayosd or wpctl fallback); work when the screen is locked |
| `Play/Pause, Next, Previous` | `playerctl`; work when locked |


## Lid

| Key | What it does |
|---|---|
| `Lid close / open` | `lid.sh close` and `lid.sh open`: with an external display only the panel is switched off |
