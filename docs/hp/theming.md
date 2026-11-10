---
title: "Theming"
parent: "HP desktop and server"
nav_order: 4
---

# Theming

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


Changing the wallpaper re-colours the whole desktop. `theme/theme.sh apply` runs **matugen** to extract source colours from the wallpaper, `theme/render.py` turns them into a **Catppuccin-named palette** (so every config keeps one vocabulary: `base`, `mantle`, `crust`, `surface0…2`, `overlay0…2`, `text`, `subtext0/1`, `red`, `peach`, `yellow`, `green`, `teal`, `sky`, `blue`, `mauve`, …) and renders the templates in `theme/templates/*` into the real config files, then reloads whatever can reload live.

## What gets themed

Hyprland borders (`conf/colors.lua`), Waybar, swaync, swayosd (CSS), rofi, hyprlock, kitty and foot, GTK 3 and 4, Qt (qt6ct), the **shell prompt** (starship), fzf, man pages, fastfetch, btop and the **Linux console** colours. Already-open GTK and Qt apps pick up the colours when restarted. Templates in `theme/templates`: `btop.theme`, `fastfetch.jsonc`, `foot.ini`, `gtk-colors.css`, `gtk-named.css`, `hypr-colors.lua`, `hyprlock.conf`, `kitty.conf`, `qt-colors.conf`, `rofi-colors.rasi`, `shell-colors.sh`, `starship.toml`, `vt-palette.sh`, `waybar-ring.css`.
**Generated files are overwritten on every change: edit the templates instead.** State lives in `~/.cache/hypr/theme/`.

## `theme.sh`

```text
theme.sh apply [wallpaper]       regenerate (default: the current wallpaper)
theme.sh source wallpaper|catppuccin|<pack>|toggle
theme.sh pack <name>             same as `source <name>`
theme.sh variant dark|light|auto auto = light 07-19 h (the "day" wallpapers), dark otherwise
theme.sh scheme <name>           tonal-spot vibrant expressive fruit-salad rainbow neutral content monochrome
theme.sh accent auto|0..4        which colour of the wallpaper becomes the accent
theme.sh contrast standard|high
theme.sh get <key> | status | candidates
```

## Theme packs

`theme/packs.py` holds named palettes mapped onto the same role names: **tokyo-night, gruvbox, nord, rose-pine, kanagawa, everforest** (`theme.sh packs` lists them). Gruvbox, Rosé Pine and Everforest have real light variants; the others use Catppuccin Latte in light mode. `theme.sh source wallpaper` goes back to wallpaper colours.

## The settings hub

`Super+I` opens `scripts/settings.sh`, a **rofi menu tree**: *Appearance* (colours from, light/dark/auto, scheme, accent, contrast), *Desktop* look, *Wallpaper*, *Power*, *System*, and *Shell*. Esc goes back one level. `Super+Alt+Y` jumps to Appearance; `Super+Alt+Shift+Y` toggles wallpaper colours ⇄ Catppuccin Mocha.

## Wallpapers

`scripts/wallpaper.sh init|next|prev|random|pick|set <file>|list` is a port of the i3 wallpaper scripts to **awww** (animated transitions) with the same day (07-19 h) and night folders, cache and index files. `Super+Y`, `Super+Shift+Y`, `Super+Ctrl+Y` (picker).

## Boot and console

`system/system-rice.sh` (root, dry run by default, `--apply`, `--undo`) themes the boot: `font` (Terminus console font), `vt` (console colours from the very first kernel message), `grub` (a GRUB theme built from the blurred wallpaper, preview with `system/build-boot-theme.py`), and opt-in `plymouth` (splash), `greeter` (greetd + tuigreet, straight into Hyprland) and `autologin` (greetd signs in by itself and the session locks at once, so after a power cut the shell, services and remote desktop come back while the keyboard still needs the password). Re-run `vt grub` after a theme change.
