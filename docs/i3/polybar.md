---
title: "Polybar"
parent: "i3 desktop"
nav_order: 6
---

# Polybar

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


## The bar

One bar, `toph` (the name is a leftover; it sits at the **bottom**: `bottom = true`), full width, `18pt` high with 5pt borders in the same translucent black (`#d9000000`), `pseudo-transparency = true` so it blends with the compositor.
The monitor comes from the `MONITOR` environment variable (empty means the primary one). i3 starts it with
`killall -q polybar; … exec polybar -c ~/.config/polybar/config.ini toph` on every start and reload, so there is never more than one bar.
`enable-ipc = true` lets `polybar-msg` control it (`Super+B` toggles it with `polybar-msg cmd toggle`; the accent script restarts it with `polybar-msg cmd restart`; the lock screen hides it while locked).

Fonts: `font-0` MesloLGS Nerd Font Mono 14 (glyphs), `font-1` JetBrains Mono light 12 (the numbers and text; weight and size are set in Settings → Top Bar).

Layout: **left** `xworkspaces xwindow`, **centre** `date`, **right** `pulseaudio brightness battery memory cpu network mic camera`. The right side is editable from the Settings app: each module is a switch (Settings → Top Bar → *Shown in the bar*), which rewrites the `modules-right` line.

## Modules

| Module | Type | What it shows / does |
|---|---|---|
| `xworkspaces` | internal/xworkspaces | The ten workspaces. Active one has a filled box (or a thin underline; Settings → Top Bar → *Active workspace marker*), occupied ones are plain, empty ones are dimmed, urgent ones turn red |
| `xwindow` | internal/xwindow | Title of the focused window, cut at 60 characters |
| `date` | internal/date | `Mon 10 Nov  13:00`, updates every 5 s; `date-alt` is the full ISO date with seconds |
| `pulseaudio` | internal/pulseaudio | Volume percentage with an icon, or *muted* |
| `brightness` | custom/script | `bri-follow.sh`: reads the backlight from sysfs and waits on a private fifo (no polling process). Click = 100 %, scroll = ±1 % (`osd.sh bri up1/down1`) |
| `battery` | internal/battery | `BAT0` on `AC0`: charging animation, discharge ramp, `Full`; polls every 5 s |
| `memory` | internal/memory | Used memory percentage every 5 s; click opens the task monitor (`sysmon.sh`) |
| `cpu` | internal/cpu | CPU percentage every 5 s; click opens the task monitor |
| `network` | custom/script | `iwd-status.sh`: asks `iwctl station wlan0 show` and prints the SSID or *Disconnected* every 5 s |
| `mic` | custom/script | `mic-follow.sh`: event driven through `pactl subscribe`; grey *live* or red *muted*; click toggles mute |
| `camera` | custom/ipc | `camera.sh bar`: a red camera while any program has the webcam open (the display agent pings it) |
| `systray`, `filesystem`, `xkeyboard` | defined, not used | Kept in the file in case I want them back |

The old `wlan`/`eth` modules are commented out ("to avoid errors") in favour of the single `network` script, because the machine uses `iwd` and not NetworkManager.

## Helper scripts (`polybar/scripts`)

- **`bri-follow.sh`** reads `max_brightness` once, then loops: print the percentage when it changed, then `read -t 0.4` on a fifo. Zero extra processes.
- **`mic-follow.sh`** prints the state, then reads lines from a `pactl subscribe` fifo and re-prints on any `source` or `server` event. Its traps kill the `pactl` child so a polybar restart leaves nothing behind.
- **`iwd-status.sh`** calls `iwctl` twice per interval; simple on purpose. The interface name `wlan0` is hard-coded.

## Colours and the accent

The `[colors]` table is my warm palette (`base #1c1917`, `text #e7dfd3`, `mauve #e0a458` is the accent …); see [Colours, accent and fonts](theme.html). The accent script edits the `mauve = …` line, so the active workspace follows the accent setting.

## Things that bite

- The `network` module shows your **Wi-Fi name** in the bar, so I leave it out of screenshots (see [How the screenshots are made](screenshots.html)).
- A polybar restart is cheap, but anything that restarts it on a timer would flicker; nothing does.
