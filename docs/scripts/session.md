---
title: "Session helpers"
parent: "Scripts"
nav_order: 4
---

# Session helpers

Small tools behind my keybindings and the bar: caffeine, screenshots, OCR, the power menu, the scratchpad and so on.

Each script has a short explanation, then a block of **facts that are extracted from the script itself** (settings it reads, programs it calls, files it touches), so the list stays honest when the script changes. Scripts live in `~/.config/scripts` (the repo's `scripts/` folder); `install.sh` copies them there.

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


## Scripts on this page

- [`caffeine.sh`](#caffeinesh)
- [`autocaffeine.sh`](#autocaffeinesh)
- [`pin.sh`](#pinsh)
- [`tablet.sh`](#tabletsh)
- [`scratch.sh`](#scratchsh)
- [`shot.sh`](#shotsh)
- [`ocr.sh`](#ocrsh)
- [`osd.sh`](#osdsh)
- [`keys.sh`](#keyssh)
- [`sysmon.sh`](#sysmonsh)
- [`camera.sh`](#camerash)
- [`power-menu.py`](#power-menupy)
- [`alarm.py`](#alarmpy)
- [`login-apply.sh`](#login-applysh)
- [`pen-setup.sh`](#pen-setupsh)
- [`lag-now`](#lag-now)
- [`toggle-touchpad.sh`](#toggle-touchpadsh)


### `caffeine.sh`

`scripts/caffeine.sh` · 10 lines · needs root: **no**

Manual caffeine. `on` creates `$XDG_STATE_HOME/caffeine` and runs `xset s off -dpms` (no auto-lock and no screen blanking; closing the lid still suspends, and `Super+Shift+L` still locks). `off` removes the file and asks `power-watch.sh timers` to restore the timers for the current power source.
`status` prints `on`, `auto` (autocaffeine is holding the screen) or `off`.

**Header comment in the script**

```text
rog-tune: caffeine. While on: no auto-lock, no screen blanking (closing the lid still suspends, Super+Shift+L still locks).
  caffeine.sh toggle | on | off | status
```

| Fact (extracted from the script) | Value |
|---|---|
| Other scripts it calls | `power-watch.sh` |
| Programs it uses | `xset` |
| Files and paths it touches | `$XDG_RUNTIME_DIR/autocaffeine.on`, `${XDG_STATE_HOME:-~/.local/state}/caffeine` |


### `autocaffeine.sh`

`scripts/autocaffeine.sh` · 34 lines · needs root: **no**

Caffeine that switches itself on. The screen stays on and unlocked while a window is **fullscreen on the visible workspace** (video, presentations) or **an app is recording from the microphone** (calls); music does not count.
It is event driven: `pactl subscribe` for source-output events and an i3 subscription for fullscreen/close/workspace events feed one private fifo, and `update` re-evaluates once per burst of events. The microphone check ignores `peak`, `pavucontrol`, `volume`, `polybar` and `mission` (volume meters and monitors).
The state is the file `$XDG_RUNTIME_DIR/autocaffeine.on`. Set `AUTOCAFFEINE=0` in Settings → Power & Performance to disable it. The manual toggle works independently.

**Header comment in the script**

```text
rog-tune: automatic caffeine. The screen stays on and unlocked while a window is fullscreen on the visible workspace (video,
presentations) or an app is using the microphone (calls); otherwise the normal lock/blank timers apply. Music does not count.
Event driven (i3 + PulseAudio events); the manual toggle (caffeine.sh) works independently of it.
```

| Fact (extracted from the script) | Value |
|---|---|
| Settings it reads (`settings.env`) | `AUTOCAFFEINE` |
| Other scripts it calls | `caffeine.sh`, `power-watch.sh` |
| Programs it uses | `i3-msg`, `jq`, `pactl`, `polybar`, `xset` |
| Files and paths it touches | `$RT/ac.XXXXXX`, `$RT/autocaffeine.on`, `$RT/autocaffeine.pid`, `~/.config/rog/settings.env` |


### `pin.sh`

`scripts/pin.sh` · 7 lines · needs root: **no**

Pins the focused window: `floating enable, sticky enable, resize set 900 560, move position center`. Run it again and it does `sticky disable, floating disable`, putting the window back into the tiling tree. Sticky means it follows me to every workspace, which is how a video or a note stays visible.

**Header comment in the script**

```text
rog-tune: pin the focused window (floating + sticky), or put it back
```

| Fact (extracted from the script) | Value |
|---|---|
| Programs it uses | `i3-msg`, `jq` |


### `tablet.sh`

`scripts/tablet.sh` · 19 lines · needs root: **yes (it calls sudo itself)**

Tablet mode is an on-screen keyboard (`onboard`) docked at the bottom, which pops up when a text field gets focus (`org.onboard.auto-show`). It is **off at every login** (nothing starts it) and needs `sudo pacman -S onboard`. Turning it on also removes the autorotate lock, because tablets rotate.

**Header comment in the script**

```text
rog-tune: tablet mode = an on-screen keyboard (onboard) docked at the bottom that appears when a text field gets focus.
Off by default and after every login. Needs: sudo pacman -S onboard
  tablet.sh toggle | on | off | status
```

| Fact (extracted from the script) | Value |
|---|---|
| Programs it uses | `gsettings`, `onboard`, `pacman` |
| Files and paths it touches | `${XDG_STATE_HOME:-~/.local/state}/autorotate.lock` |


### `scratch.sh`

`scripts/scratch.sh` · 7 lines · needs root: **no**

My notepad. It opens `~/Documents/scratch.md` in a floating kitty with class `scratch` running Neovim with three extra options: autosave on `TextChanged`, `TextChangedI` and `InsertLeave`, soft-wrap at word boundaries, and the cursor on the last line.
The i3 rule `for_window [class="^scratch$"] floating enable, resize set 1100 760, move position center` makes it a centred window. Running the script while the notepad is open kills it, so `Super+N` is a toggle. It exists because gedit crashed on this machine; see [Changes](../changes/).

**Header comment in the script**

```text
scratch: my notepad. One persistent file (~/Documents/scratch.md) in a floating Neovim window that autosaves as I type, so there is
nothing to save and nothing to lose. Super+N opens it; Super+N again (or :q) closes it. It also opens through Spotlight: type "scratch".
```

| Fact (extracted from the script) | Value |
|---|---|
| Programs it uses | `kitty` |
| Files and paths it touches | `~/Documents/scratch.md` |


### `shot.sh`

`scripts/shot.sh` · 21 lines · needs root: **no**

Screenshots with `scrot`. Everything goes to the clipboard as a PNG (`xclip -t image/png`), so it pastes straight into browsers, chat and editors; unless `SHOT_SAVE=0` it is also saved as `~/Pictures/screenshot_YYYY-MM-DD_HH-MM-SS.png`.
Modes: `full`, `area` (select with the mouse; Esc cancels quietly), `window` (focused), `area-clip` (clipboard only, never a file). It is deliberately silent: no popup, no sound.

**Header comment in the script**

```text
rog-tune: screenshot → clipboard (PNG, pastes into browsers/chat/editors) + ~/Pictures. Silent.
usage: shot.sh full|area|window|area-clip      (area-clip: clipboard only, no file)
```

| Fact (extracted from the script) | Value |
|---|---|
| Settings it reads (`settings.env`) | `SHOT_SAVE` |
| Programs it uses | `scrot`, `xclip` |
| Files and paths it touches | `$XDG_RUNTIME_DIR/shot.XXXXXX.png`, `~/.config/rog/settings.env`, `~/Pictures`, `~/Pictures.` |


### `ocr.sh`

`scripts/ocr.sh` · 6 lines · needs root: **no**

Select an area with `scrot -s`, run `tesseract` (English, page segmentation mode 6), trim trailing spaces and put the text on the clipboard. Needs `tesseract` and `tesseract-data-eng`.

**Header comment in the script**

```text
rog-tune: select an area on screen, put the text in it on the clipboard (needs tesseract + tesseract-data-eng)
```

| Fact (extracted from the script) | Value |
|---|---|
| Programs it uses | `scrot`, `tesseract`, `xclip` |
| Files and paths it touches | `$XDG_RUNTIME_DIR/ocr.XXXXXX.png` |


### `osd.sh`

`scripts/osd.sh` · 22 lines · needs root: **no**

Volume, microphone and brightness actions, silent (the bar shows the state). Volume uses `pactl` in 5 % steps and unmutes when raising. Brightness uses `brightnessctl` and, if present, the `nvidia_wmi_ec_backlight` device (the one that really dims this panel).
After a brightness change it saves the value to `~/.local/state/rog/brightness`; `login-apply.sh` restores it on the next login (the greeter raises a nearly-dark screen so the login box stays readable).
`up1` and `down1` are 1 % steps (the bar's scroll wheel uses them).

**Header comment in the script**

```text
rog-tune: volume / mic / brightness actions. Silent: no bars, no popups (the bar shows the state).
```

| Fact (extracted from the script) | Value |
|---|---|
| Programs it uses | `brightnessctl`, `pactl` |
| Files and paths it touches | `/sys/class/backlight/nvidia_wmi_ec_backlight`, `~/.local/state/rog`, `~/.local/state/rog/brightness` |


### `keys.sh`

`scripts/keys.sh` · 38 lines · needs root: **no**

`Super+F1` / `Super+/`. A small Python program inside the script reads `i3/config`, joins continued lines, expands `set` variables, prettifies key names (`Mod4` → `Super`, `XF86MonBrightnessUp` → *Brightness Up* …), summarises each command, and prints one aligned line per `bindsym` (resize-mode ones are prefixed `[resize]`).
The list goes into `rofi -dmenu` with the Catppuccin theme at a big font, so typing filters it. It always reflects the real config because it parses it every time.

**Header comment in the script**

```text
rog-tune: show every i3 keybind in a searchable rofi list (type to filter, Esc to close)
```

| Fact (extracted from the script) | Value |
|---|---|
| Programs it uses | `rofi` |
| Files and paths it touches | `~/.config/i3/config`, `~/.config/rofi/catppuccin-mocha.rasi` |


### `sysmon.sh`

`scripts/sysmon.sh` · 4 lines · needs root: **no**

Opens the first GUI task monitor it finds (`missioncenter`, `resources`, `gnome-system-monitor`) and otherwise runs `btop` inside kitty with class `sysmon`. Bound to `Super+Shift+Esc`, and clicking CPU or memory in the bar runs it too.

**Header comment in the script**

```text
rog-tune: open a GUI task monitor: per-process CPU/RAM/disk/GPU, per-app grouping
```

| Fact (extracted from the script) | Value |
|---|---|
| Programs it uses | `btop`, `kitty` |


### `camera.sh`

`scripts/camera.sh` · 4 lines · needs root: **no**

The polybar custom/ipc module for the *camera in use* chip: prints a red camera glyph and `cam` while `$XDG_RUNTIME_DIR/camera.on` exists (the display agent maintains that file) and nothing otherwise.

**Header comment in the script**

```text
rog-tune: polybar camera indicator. The display agent sets the flag while any app has the webcam open; the bar shows a red camera then.
```

| Fact (extracted from the script) | Value |
|---|---|
| Programs it uses | `polybar` |
| Files and paths it touches | `$XDG_RUNTIME_DIR/camera.on` |


### `power-menu.py`

`scripts/power-menu.py` · 150 lines · needs root: **no**

`Super+Esc`. A GTK3 window of six big tiles: Lock, Log out, Sleep, Hibernate, Restart, Shut down. `h`/`l`, arrows or Tab move, `1`-`6` pick, Enter runs, Esc or `q` closes. Lock and Sleep run at once; the other four need a **second Enter** (the tile turns solid and the line below says what will happen).
Hibernate is only offered when `resume=` is on the kernel command line. The header line shows host, uptime and battery. The look follows `APPEARANCE` (light, dark, schedule) and the accent colour. Pressing the key while the menu is open closes it (it looks for another copy of itself and sends it SIGTERM).
Window class `RogPower` (see the `for_window` rule). Commands: `lock.sh`, `i3-msg exit`, `systemctl suspend|hibernate|reboot|poweroff`.

**Header comment in the script**

```text
rog-tune: power menu (Super+Escape). One row of big tiles: Lock, Log out, Sleep, Hibernate, Restart, Shut down.
  h / l / arrows / Tab move · 1-6 pick · Enter runs · Esc or q closes
  Lock and Sleep run at once; Log out, Hibernate, Restart and Shut down ask for a second Enter so a slip never ends the session.
```

| Fact (extracted from the script) | Value |
|---|---|
| Settings it reads (`settings.env`) | `ACCENT_HEX`, `ACCENT_MODE`, `APPEARANCE`, `NIGHT_END`, `NIGHT_START` |
| Programs it uses | `i3-msg`, `systemctl` |
| Files and paths it touches | `/proc/cmdline`, `/proc/uptime`, `/sys/class/power_supply` |


### `alarm.py`

`scripts/alarm.py` · 91 lines · needs root: **no**

The window a Spotlight timer or reminder shows when it rings: a centred card (`RogAlarm`) with the message, which stays until I press Enter or Esc; `S` snoozes for 5 minutes (it schedules itself again with `systemd-run --user --on-active=300s`, and records the alarm in `alarms.json` so Spotlight can list it).
A sound plays up to four times (`alarm-clock-elapsed.oga` through `paplay`) unless `ALARM_SOUND=0`. It is started by `systemd-run --user` from Spotlight, with `DISPLAY`/`XAUTHORITY`/bus variables passed along.

**Header comment in the script**

```text
rog-tune: the window a Spotlight timer or reminder shows when it rings. Stays until I dismiss it (Enter / Esc); S snoozes 5 minutes.
  alarm.py "message"        (started by systemd-run --user when the time comes)
```

| Fact (extracted from the script) | Value |
|---|---|
| Settings it reads (`settings.env`) | `ACCENT_HEX`, `ACCENT_MODE`, `ALARM_SOUND`, `APPEARANCE`, `NIGHT_END`, `NIGHT_START` |
| Programs it uses | `paplay`, `systemd-run` |
| Files and paths it touches | `/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga` |


### `login-apply.sh`

`scripts/login-apply.sh` · 10 lines · needs root: **no**

Runs **once per login** (an `exec`, not `exec_always`, so reloads do not repeat it). If `MIC_MUTE_LOGIN=1` it mutes the default microphone after 3 s. It then restores the brightness I last chose from `~/.local/state/rog/brightness`, because the greeter may have raised a dark screen so the login box could be read.

**Header comment in the script**

```text
rog-tune: things that happen once per login (not on every i3 restart)
```

| Fact (extracted from the script) | Value |
|---|---|
| Settings it reads (`settings.env`) | `MIC_MUTE_LOGIN` |
| Programs it uses | `brightnessctl`, `pactl` |
| Files and paths it touches | `/sys/class/backlight/nvidia_wmi_ec_backlight`, `~/.config/rog/settings.env`, `~/.local/state/rog/brightness` |


### `pen-setup.sh`

`scripts/pen-setup.sh` · 46 lines · needs root: **no**

The ASUS stylus (`ELAN9008:00 04F3:40FD Stylus`) and touchscreen get mapped to the internal panel with `xinput map-to-output`, the stylus is enabled, a linear pressure curve is set with `xsetwacom` (if installed), the buttons are mapped (button 2 → right click, button 3 → middle click) and the touchscreen ignores touches while typing.
The panel name is looked up (`eDP-1` or `eDP-2`). If the pen is not present it logs *Pen not detected* and exits with 1.

**Header comment in the script**

```text
pen-setup: map the ASUS stylus and touchscreen to the internal panel (run once at login by i3).
  Needs: xinput (and xsetwacom, optional, for the pressure curve). No root.
  What it does: maps the stylus (ELAN9008:00 04F3:40FD Stylus) and the touchscreen to the panel, enables the stylus, sets a linear
  pressure curve, makes pen button 2 a right click and button 3 a middle click, and ignores touch while typing.
  Exits 1 with "Pen not detected" when the stylus is not present. The panel name (eDP-1 or eDP-2) is looked up at run time.
```

| Fact (extracted from the script) | Value |
|---|---|
| Programs it uses | `xinput`, `xrandr`, `xsetwacom` |


### `lag-now`

`scripts/lag-now` · 26 lines · needs root: **no**

Press `Super+Shift+F12` when the machine lags. It appends a one-second snapshot to `~/lag-notes.log`: the kernel's pressure-stall averages (10 s / 60 s / 300 s) for CPU, IO and memory, the busiest processes, anything waiting on disk, biggest memory users, RAM and swap, CPU frequency, governor and energy preference, thermal-throttle counts and temperatures, GPU load, the refresh rate, recent kernel warnings and recently started or failed services.
Nothing runs in the background: the kernel keeps the pressure averages itself, which is why a snapshot taken *after* a stall still shows it. I added it instead of a recorder because a recorder is one more thing that runs all the time.

**Header comment in the script**

```text
lag-now: press the key when the machine lags. It takes a one-second snapshot of what the machine is doing and what the kernel
remembers about the last few minutes (the kernel keeps pressure averages by itself, so nothing has to run in the background).
Result: appended to ~/lag-notes.log. Tell me the time you pressed it.
```

| Fact (extracted from the script) | Value |
|---|---|
| Programs it uses | `notify-send`, `xrandr` |
| Files and paths it touches | `/proc/pressure/`, `/proc/sys/kernel/hostname`, `/sys/class/drm/card*/device/gpu_busy_percent`, `/sys/devices/system/cpu/cpu*/thermal_throttle/core_throttle_count`, `/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference`, `/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq`, `/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`, `~/lag-notes.log`, `~/lag-notes.log.` |


### `toggle-touchpad.sh`

`i3/toggle-touchpad.sh` · 12 lines · needs root: **no**

`XF86TouchpadToggle`. Finds the touchpad's xinput id, reads `Device Enabled` and flips it with `xinput enable|disable`.

**Header comment in the script**

```text
toggle-touchpad: turn the touchpad on or off (bound to the XF86TouchpadToggle key in i3/config).
  Needs: xinput. No root. Finds the touchpad by name in `xinput list`, reads "Device Enabled" and flips it.
```

| Fact (extracted from the script) | Value |
|---|---|
| Programs it uses | `xinput` |
