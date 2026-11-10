---
title: "Colours, accent and fonts"
parent: "i3 desktop"
nav_order: 10
---

# Colours, accent and fonts

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


## The palette

A warm dark palette instead of the usual cool Catppuccin blues. It is defined once in `polybar/config.ini` (`[colors]`) and echoed in i3 and kitty.

| Name | Hex | Used for |
|---|---|---|
| `base` | `#1c1917` | Background |
| `mantle` | `#14110f` | Darker background (unfocused window border background) |
| `crust` | `#0f0d0c` | Darkest (text on the active workspace box) |
| `text` | `#e7dfd3` | Foreground |
| `subtext0` / `subtext1` | `#b5aa9a` / `#cfc5b5` | Dimmer text, disabled items |
| `surface0` / `1` / `2` | `#2b2622` / `#3a342e` / `#4a4239` | Borders and panels |
| `overlay0` / `1` / `2` | `#6e655a` / `#857b6e` / `#9b9084` | Muted text |
| `mauve` | `#e0a458` | **The accent** (active workspace, focused border) |
| `red`, `maroon`, `peach`, `yellow`, `green`, `teal`, `blue`, `lavender`, `sapphire`, `sky`, `pink`, `flamingo`, `rosewater` | `#e06c5a` `#c8786a` `#e39a5f` `#e5c07b` `#a3a27a` `#b8a58a` `#d4a373` `#e0b88a` `#c99a6b` `#d9b48f` `#d98c7a` `#e6b3a1` `#f0d9c8` | Warm variants of the usual names |

## The accent colour

The accent is **one setting, applied in three places**:

1. **Spotlight, Settings, the power menu and the alarm window** read `ACCENT_MODE` / `ACCENT_HEX` themselves and re-style their CSS.
2. **Polybar's active workspace** (`mauve = …`) and
3. **the focused window's border** (`client.focused`) are edited by `accent.sh`.

(`lock.sh` reads `ACCENT_HEX` into a variable but its current options use fixed translucent-white colours, so the lock screen does not follow the accent.)

Modes (Settings → General → *Accent colour*): **Amber** (`#e0a458`, the default), **From the wallpaper** (`accent.sh wallpaper` picks the most saturated mid-lightness colour of the current wallpaper), **Custom** (the colour chooser; picking a colour switches the mode to Custom). *Theme* (light / dark / follow the night schedule) is `APPEARANCE`.

## Fonts

| Where | Font |
|---|---|
| i3 title font (rarely visible: no title bars) | Meslo LGM Nerd Font 11 |
| Polybar glyphs / text | MesloLGS Nerd Font Mono 14 / JetBrains Mono light 12 |
| kitty | JetBrainsMono Nerd Font 13 |
| GTK apps | Noto Sans 11 |
| Lock screen | Noto Sans Light (clock), Noto Sans Medium (date, name) |

## GTK, icons, cursor

`gtk-3.0/settings.ini` and `gtk-4.0/settings.ini` are identical: dark theme preferred, **Papirus-Dark** icons, Adwaita cursor at 32 px, animations off, cursor blink off. (GTK animations off is deliberate: fewer frames to draw.)

## Wallpapers

`~/Pictures/wallpapers/day` and `/night`; `Super+Y` / `Super+Shift+Y` step forward and back, Settings → Wallpaper sets the day/night switch hours and an automatic change interval. The current wallpaper's path is in `~/.cache/current_wallpaper`; changing it also refreshes the lock screen image, the login screen wallpaper and (in *From the wallpaper* mode) the accent.
