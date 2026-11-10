---
title: "Appearance and settings"
parent: "Spotlight"
nav_order: 8
---

# Appearance and settings

All of these live in `~/.config/rog/settings.env` and have rows in **Settings → Spotlight** and **Settings → General**.

| Setting | Values | Effect |
|---|---|---|
| `SPOT_OPACITY` | 35-100 in the slider (30-100 accepted), default 62 | How opaque the box is. Lower is more see-through. Applied the next time it opens |
| `APPEARANCE` | `light`, `dark`, `schedule` | Light palette, dark palette, or dark between `NIGHT_START` and `NIGHT_END` |
| `ACCENT_MODE`, `ACCENT_HEX` | `amber`, `wallpaper`, `custom` | The selection and caret colour |
| `SPOT_RECENTS` | `1`/`0` | The home view with recent apps and files |

## How the look is built

The CSS is written once for the **light palette with the amber accent** (`rgba(238,233,224,alpha)` background, `#2a251e` text, `#b86f12` caret) and then **rewritten on demand**: for dark mode the light colours are replaced by dark ones, the accent is swapped for the chosen one (the caret is derived: darker in light mode, lighter in dark mode), and `__ALPHA__` is replaced by the opacity.
Because Spotlight and Settings share one process in the daemon, every rule is **prefixed with `window.spotlight`** (`scope()`), so Spotlight's styles can never leak into the Settings window.

Rounded corners (26 px) come from picom's `corner-radius-rules` (see [Compositor](../i3/compositor.html)); the blur behind the box is picom's too, which is why `picom-bat.conf` has a rule that blurs *only* Spotlight.

## Geometry

860 px wide (1000 px for the preview and the app grid), centred on the primary monitor, 15 % of the screen height from the top. i3 places it (`for_window [class="^Spotlight$"] floating enable, border none, move position center, move up 260px`), and the program re-places itself with `i3-msg … move absolute position` after every width change.
