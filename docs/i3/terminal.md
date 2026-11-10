---
title: "Terminal (kitty)"
parent: "i3 desktop"
nav_order: 8
---

# Terminal (kitty)

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


kitty is my terminal (`Super+T`; `Super+Enter` runs whatever `i3-sensible-terminal` picks). The config is two files: `kitty.conf` and `theme.conf` (included by the first).

## `kitty.conf`

| Setting | Value | Why |
|---|---|---|
| `font_family` | JetBrainsMono Nerd Font | Icons for neo-tree, lualine, the prompt |
| `font_size` | 13.0 | The panel is 2560×1600 at a high DPI |
| `window_padding_width` | 8 | |
| `repaint_delay`, `input_delay` | 6, 1 | Lower input latency (added by the `kitty` part of `rog-lean-session.sh`) |
| `enable_audio_bell` | no | |

## Vim-style scrollback

`ctrl+shift+space` opens the scrollback in kitty's pager and the pager has vim-like keys:

- Motion: `h j k l`, `0`, `^`, `$`, `w`, `e`, `b`, `ge`; paging `ctrl+u/d/b/f`; `gg` / `G`.
- Search: `/`, `?`, `n`, `N`.
- Selection: `v` (characters), `V` (lines), `ctrl+v` (block); `y` yanks; `esc` leaves.

Kitty may print *Shortcut: scrollback_pager has unknown key, ignoring*: these `map scrollback_pager …` lines use a syntax that kitty versions ignore with a warning. It is harmless but it is why you may see that line when running kitty from a terminal or a script.

## `theme.conf`: warm black, translucent

`background #000000` with `background_opacity 0.66`, `dynamic_background_opacity yes`: with picom running, the blurred wallpaper shows through. Foreground `#E7DFD3`, selection background `#E0A458` (the accent), cursor `#E0A458`, URL colour `#E5C07B`, and a 16-colour palette in the same warm tones (`color1 #EA6962`, `color2 #A9B665`, `color3 #D8A657`, `color4 #7DAEA3`, `color5 #D3869B`, `color6 #89B482`).
The comment in the file lists the opacity keys: `ctrl+shift+a` then `m` / `l` = more / less opaque, `a` then `1` = fully opaque, `a` then `d` = back to the default.

The Settings app has an **Opacity** slider (Windows & Terminal → Terminal): it rewrites `background_opacity` and sends kitty `SIGUSR1`, which makes kitty reload its config so open terminals change immediately.

## Window classes I use

`kitty --class scratch` (the notepad), `--class rog-sync` (floating update/backup windows: 1100×640 centred, `for_window` rule), `--class sysmon` (btop fallback).
