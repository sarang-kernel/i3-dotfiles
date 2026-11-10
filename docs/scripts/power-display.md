---
title: "Power, display and input"
parent: "Scripts"
nav_order: 3
---

# Power, display and input

The scripts that react to the power source, the screen and the input devices. Most of them are started by i3 and keep running.

Each script has a short explanation, then a block of **facts that are extracted from the script itself** (settings it reads, programs it calls, files it touches), so the list stays honest when the script changes. Scripts live in `~/.config/scripts` (the repo's `scripts/` folder); `install.sh` copies them there.

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


## Scripts on this page

- [`power-watch.sh`](#power-watchsh)
- [`power-mode.sh`](#power-modesh)
- [`display-agent.py`](#display-agentpy)
- [`nightlight.sh`](#nightlightsh)
- [`autorotate.sh`](#autorotatesh)
- [`input-apply.sh`](#input-applysh)
- [`accent.sh`](#accentsh)
- [`wallpaper-timer.sh`](#wallpaper-timersh)


### `power-watch.sh`

`scripts/power-watch.sh` · 122 lines · needs root: **no**

This is the brain of the power behaviour. It is started by i3 (`exec_always`), asks `upower --monitor` to wake it on every plug and unplug, and then re-applies
everything that depends on the power source:

1. **Performance mode** (`MODE_AC` / `MODE_BAT`, see `power-mode.sh`) turns into a CPU profile through `powerprofilesctl` (`quiet` → `power-saver`, `balanced`, `performance`).
2. **Refresh rate**: `target_hz` picks the rate (cinema mode beats everything, then Quiet = 60 Hz, then the idle rate when the adaptive flag is set, otherwise `RATE_AC` / `RATE_BAT`).
   Any rate between 60 and 165 Hz works: 60 and 165 are the panel's own modes; every other rate is made on the fly with `xrandr --newmode 2560x1600_<hz>` using the same timings at a different pixel clock
   (the panel is variable-refresh, 58-165 Hz). The panel is looked up at run time (`eDP-1` or `eDP-2`, depending on which GPU driver registered first).
3. **Compositor variant**: `style_apply` repoints the `picom.conf` symlink at `picom-ac.conf` (blur) or `picom-bat.conf` (no blur) and sends picom `SIGUSR1` so it reloads.
4. **Lock and screen-off timers** (`LOCK_AC` 10 min / `OFF_AC` 15, `LOCK_BAT` 2 / `OFF_BAT` 3 by default) go to `xset s` and `xset dpms`. If caffeine is on (a state file) or autocaffeine is active the timers are switched off instead.
5. **Low-battery override** (`autoquiet_check`): at or below `AUTOQUIET_PCT` (20 %) on battery it creates `$XDG_RUNTIME_DIR/autoquiet.on` and `mode_of` answers `quiet` until you plug in or the charge is five points higher.

It is also a small command-line tool; the other scripts and the Settings app call it:

| Call | What it does |
|---|---|
| `power-watch.sh` | Run in the background (what i3 starts). Kills any older copy first. |
| `power-watch.sh once ac`, `once bat`, `once auto` | Apply once and exit, to try a power source without unplugging. |
| `power-watch.sh timers` | Re-apply only the lock and screen-off timers (caffeine uses it when it turns off). |
| `power-watch.sh display` | Re-apply performance mode, refresh rate and CPU profile (Settings and `power-mode.sh` use it). |
| `power-watch.sh autoquiet` | Re-check the low-battery override now. |
| `power-watch.sh refresh` | Apply only the refresh rate that fits right now. The display agent calls this. It refuses while `i3lock` runs or the screen is off, because a mode-set could wake the panel. |
| `power-watch.sh rate` | Print the configured rate for the current power source (60 in Quiet). |

`ROG_PS` (the power-supply directory) and `ROG_DRY` can be set to test the logic without touching the hardware.

**Header comment in the script**

```text
rog-tune: power-aware behaviour, event driven (upower). Re-applied on every plug/unplug.
  AC:      Balanced mode (blur, 90 Hz), lock after 10 min / screen off after 15
  battery: Quiet mode (power-saver, 60 Hz, no blur), lock after 2 min / screen off after 3
  (modes and rates can be changed in Settings; see power-mode.sh)
  power-watch.sh            run in the background (started by i3)
  power-watch.sh once ac|bat|auto    apply once and exit (to try it)
  power-watch.sh timers              re-apply only the lock/blank timers (caffeine uses it)
  power-watch.sh display             re-apply only the performance mode, refresh rate and CPU profile (Settings and power-mode.sh use it)
  power-watch.sh autoquiet           re-check the low-battery Quiet override now
  power-watch.sh refresh             apply only the refresh rate that fits right now (Quiet / cinema / idle / my setting)
  power-watch.sh rate                print my configured rate for the current power source (60 in Quiet)
```

| Fact (extracted from the script) | Value |
|---|---|
| Settings it reads (`settings.env`) | `AUTOQUIET`, `AUTOQUIET_PCT`, `CINEMA_HZ`, `IDLE_HZ`, `LOCK_AC`, `LOCK_BAT`, `MODE_AC`, `MODE_BAT`, `OFF_AC`, `OFF_BAT`, `RATE_AC`, `RATE_BAT` |
| Other scripts it calls | `nightlight.sh`, `power-mode.sh` |
| Programs it uses | `i3lock`, `picom`, `powerprofilesctl`, `upower`, `xrandr`, `xset` |
| Files and paths it touches | `$XDG_RUNTIME_DIR/autocaffeine.on`, `$XDG_RUNTIME_DIR/autoquiet.on`, `$XDG_RUNTIME_DIR/power-watch.pid`, `${XDG_STATE_HOME:-~/.local/state}/caffeine`, `/sys/class/power_supply`, `~/.config/picom`, `~/.config/rog/settings.env` |


### `power-mode.sh`

`scripts/power-mode.sh` · 20 lines · needs root: **no**

Quiet, Balanced or Performance for **the power source I am on right now**. The choice is stored in `settings.env` as `MODE_AC` or `MODE_BAT`, so plugging in or out later restores the mode I chose for that source.

- **Quiet**: power-saver CPU profile (capped near 4 GHz, quiet fans), 60 Hz, no blur, no dimming.
- **Balanced**: everyday. On AC it also means blur and 90 Hz.
- **Performance**: CPU and fans unrestricted (louder, hotter).

Defaults: Balanced on AC, Quiet on battery. `cycle` rotates through the three (that is `Super+Alt+M`). Choosing a mode on purpose deletes the low-battery override flag, because a deliberate choice beats the automatic Quiet.
It writes the key with `sed` (or appends it) and then runs `power-watch.sh display`. Spotlight ("performance mode …") and the Settings app change exactly the same thing.

**Header comment in the script**

```text
rog-tune: performance mode for the power source I am on right now (saved, so it is also what plug/unplug restores)
  power-mode.sh quiet | balanced | performance | cycle | status
  Quiet       least battery: power-saver CPU profile (CPU capped near 4 GHz, quiet fans), 60 Hz, no blur or dimming
  Balanced    everyday
  Performance CPU and fans unrestricted (louder, hotter)
  Defaults: Balanced on AC, Quiet on battery. Spotlight and Settings change the same thing.
```

| Fact (extracted from the script) | Value |
|---|---|
| Settings it reads (`settings.env`) | `MODE_AC`, `MODE_BAT` |
| Other scripts it calls | `power-watch.sh` |
| Files and paths it touches | `$XDG_RUNTIME_DIR/autoquiet.on`, `/sys/class/power_supply/*/online`, `~/.config/rog/settings.env` |


### `display-agent.py`

`scripts/display-agent.py` · 225 lines · needs root: **no**

One small Python process with no polling loop while it has nothing to do. It does four jobs:

1. **Adaptive refresh.** It reads the idle time from the X screensaver extension through `ctypes` and `libxcb` (no subprocess). After `ADAPTIVE_IDLE_S` seconds (default 60) without input it creates the flag file
   `$XDG_RUNTIME_DIR/adaptive.low` and asks `power-watch.sh refresh` to apply the idle rate. While the flag exists it blocks on `xinput test-xi2 --root`, so the first key or touch brings the full rate back with zero polling.
   It only acts when the configured rate is at least `ADAPTIVE_MIN_HZ` (110) and higher than `IDLE_HZ`: I measured on this laptop that 60 Hz and 90 Hz draw the same power, while 120 Hz costs about 0.4 W and 165 Hz about 0.5 W more.
   It never lowers the rate while locked, with the screen off, with caffeine on, or while audio plays (it looks again in 30 s).
2. **Cinema mode.** It subscribes to i3 events. When a window of a known video player (`mpv`, `vlc`, `celluloid`, `smplayer`, `totem`, `kodi`, `haruna`, `mplayer`, `jellyfin media player` and a few more) is fullscreen on the visible workspace it creates `cinema.on`,
   and `power-watch.sh` picks the rate that shows every film frame for the same number of refreshes (`film_rate`: fps × the smallest integer that reaches 58 Hz or more, at most 165). For mpv it asks the control socket (`~/.cache/mpv-ipc`, enabled in `mpv/mpv.conf`)
   for `container-fps` and writes the exact rate to `cinema.hz`; for other players `CINEMA_HZ` (71.928 Hz, for 23.976 fps films) is used.
3. **Camera indicator.** A thread watches the webcam's device node with `inotify`, checks `fuser`, writes `$XDG_RUNTIME_DIR/camera.on` and pings polybar (`polybar-msg action "#camera.hook.0"`) so the red *cam* chip appears only while a program has the camera open.
4. **Workspace icons** (when `WS_ICONS=1`): renames workspaces to `N <glyphs>` according to the windows on them. Binds use `workspace number N`, so renaming is safe. `SIGUSR1` forces a sync.

It makes sure only one copy exists (it kills every other `display-agent.py`, not only the one in the pid file, because after an i3 restart a stale copy can survive), and on `SIGTERM` it removes its flags and restores the normal refresh rate.

**Header comment in the script**

```text
Camera in use: inotify on the webcam's device node (no polling); the flag file + a bar ping when it changes.
```

| Fact (extracted from the script) | Value |
|---|---|
| Settings it reads (`settings.env`) | `ADAPTIVE`, `ADAPTIVE_IDLE_S`, `CINEMA`, `IDLE_HZ`, `WS_ICONS` |
| Other scripts it calls | `power-watch.sh` |
| Programs it uses | `fuser`, `i3-msg`, `i3lock`, `kitty`, `pactl`, `polybar-msg`, `xinput`, `xset` |
| Files and paths it touches | `/sys/class/video4linux` |


### `nightlight.sh`

`scripts/nightlight.sh` · 27 lines · needs root: **no**

A warm night tint through the display's gamma ramp: `xrandr --output <panel> --gamma R:G:B`. No extra package, no popup.

- Modes are stored in `$XDG_STATE_HOME/nightlight/mode`: `auto` (follow the schedule), `on`, `off`.
- The schedule is `NIGHT_START`-`NIGHT_END` (hours; defaults 19 and 7).
- The tint is `NIGHT_GAMMA`, which the Settings app derives from the *Warmth* slider (`NIGHT_K`, 2700-6000 K) with a black-body approximation (`gamma_for` in `settings.py`). The fallback is `1.0:0.81:0.65` (about 4000 K).
- `toggle` flips what is currently on or off; `auto` goes back to the schedule; `reapply` re-applies the current state (the rotation script and `power-watch.sh` call it, because a rotation or a mode-set can reset the ramp).
- `daemon` re-evaluates every 5 minutes (or immediately when something writes to its private fifo) so the tint switches at the scheduled hour without cron.

**Header comment in the script**

```text
rog-tune: night tint through the display's gamma ramp (no extra packages, no popups).
  nightlight.sh toggle | on | off | auto | status | reapply | daemon
```

| Fact (extracted from the script) | Value |
|---|---|
| Settings it reads (`settings.env`) | `NIGHT_END`, `NIGHT_START`, `NIGHT_GAMMA`, `NIGHTLIGHT_TINT` |
| Programs it uses | `xrandr` |
| Files and paths it touches | `$XDG_RUNTIME_DIR/nightlight.pid`, `${XDG_STATE_HOME:-~/.local/state}/nightlight`, `~/.config/rog/settings.env` |


### `autorotate.sh`

`scripts/autorotate.sh` · 55 lines · needs root: **no**

Panel, touchscreen and pen rotate together with the accelerometer. It runs `monitor-sensor --accel` and maps each orientation to an `xrandr --rotate` value plus a *Coordinate Transformation Matrix* for every touchscreen and stylus
(`normal`, `left-up` → `left`, `right-up` → `right`, `bottom-up` → `inverted`). It then calls `nightlight.sh reapply`, because a rotation can reset the colour ramp.

Details that took some debugging and are worth knowing:

- `monitor-sensor` stays alive and silent when the sensor claim is refused (it only warns on stderr), and a claim made before the session is fully active is refused. So the script reads stderr too, and when it sees *Failed to claim* it kills `monitor-sensor`, waits (2 s, doubling up to 30 s) and starts it again. Rotation never depends on a single attempt at login.
- `CURRENT` is only updated after `xrandr` succeeded, so a refused rotation is retried.
- The panel name is looked up at run time instead of hard-coding `eDP-1`.
- `autorotate.sh lock` toggles `$XDG_STATE_HOME/autorotate.lock`; while it exists, nothing rotates (`Super+Shift+O`, or Settings → Windows & Terminal → *Freeze rotation*). Tablet mode removes the lock, because tablets rotate.
- It keeps a pid file and kills the previous copy on start, so an i3 restart does not stack watchers.

**Header comment in the script**

```text
rog-tune: follow the accelerometer. Panel + touchscreen + pen rotate together.
  autorotate.sh            run (event-driven, one instance)
  autorotate.sh lock       toggle "stay put" (Super+Shift+O)
```

| Fact (extracted from the script) | Value |
|---|---|
| Other scripts it calls | `nightlight.sh` |
| Programs it uses | `logger`, `monitor-sensor`, `xinput`, `xrandr` |
| Files and paths it touches | `$XDG_RUNTIME_DIR/autorotate.pid`, `${XDG_STATE_HOME:-~/.local/state}/autorotate.lock` |


### `input-apply.sh`

`scripts/input-apply.sh` · 16 lines · needs root: **no**

Applies touchpad, pointer and keyboard settings from `settings.env`: key repeat (`xset r rate KEY_DELAY KEY_RATE`, bell off), and for every input device that has the libinput properties: tapping, natural scrolling, disable-while-typing and pointer acceleration speed.
It runs on i3 `exec_always` (so reloads re-apply), and the Settings app runs it whenever one of those rows changes.

**Header comment in the script**

```text
rog-tune: apply touchpad / pointer / keyboard settings (at login, on i3 restart, and when Settings changes them)
```

| Fact (extracted from the script) | Value |
|---|---|
| Settings it reads (`settings.env`) | `KEY_DELAY`, `KEY_RATE`, `PTR_SPEED`, `TP_DWT`, `TP_NATURAL`, `TP_TAP` |
| Programs it uses | `xinput`, `xset` |
| Files and paths it touches | `~/.config/rog/settings.env` |


### `accent.sh`

`scripts/accent.sh` · 36 lines · needs root: **no**

The accent colour has to reach two places Spotlight and Settings cannot touch themselves: the polybar *active workspace* colour (`mauve = …` in `polybar/config.ini`) and the focused-window border (`client.focused` in `i3/config`).
Modes (`ACCENT_MODE`): `amber` (`#e0a458`), `custom` (`ACCENT_HEX`) and `wallpaper`. For `wallpaper` mode, `accent.sh wallpaper` samples the current wallpaper at 64×64 with ImageMagick, scores every pixel by saturation and by closeness to mid-lightness, and takes the winner as the accent (cached in `~/.cache/accent-wallpaper`).
If the colour did not change it exits without restarting anything; otherwise it edits the two files with `sed`, restarts polybar (`polybar-msg cmd restart`) and reloads i3.

**Header comment in the script**

```text
rog-tune: apply the accent colour where Spotlight/Settings cannot reach: the bar's active workspace and the focused window's border.
  accent.sh              apply what Settings -> General says (Amber, From the wallpaper, or Custom)
  accent.sh wallpaper    (called when the wallpaper changes) work out the wallpaper's accent first, then apply
```

| Fact (extracted from the script) | Value |
|---|---|
| Settings it reads (`settings.env`) | `ACCENT_HEX`, `ACCENT_MODE` |
| Programs it uses | `i3-msg`, `magick`, `polybar-msg` |
| Files and paths it touches | `~/.cache/accent-wallpaper`, `~/.cache/current_wallpaper`, `~/.config/i3/config`, `~/.config/polybar/config.ini`, `~/.config/rog/settings.env` |


### `wallpaper-timer.sh`

`scripts/wallpaper-timer.sh` · 8 lines · needs root: **no**

Creates (or removes) the automatic wallpaper timer. Every call first stops `rog-wallpaper.timer`; when `WALL_EVERY` is above zero it starts a transient systemd user timer with `systemd-run --user --unit=rog-wallpaper --on-active=Nm --on-unit-active=Nm`
that runs `wallpaper-cycle.sh`, passing `DISPLAY`, `XAUTHORITY` and the D-Bus address along. Set from Settings → Wallpaper.

**Header comment in the script**

```text
rog-tune: (re)create the timer that changes the wallpaper every WALL_EVERY minutes (0 = never; set in Settings -> Wallpaper)
```

| Fact (extracted from the script) | Value |
|---|---|
| Settings it reads (`settings.env`) | `WALL_EVERY` |
| Programs it uses | `systemctl`, `systemd-run` |
| Files and paths it touches | `~/.config/rog/settings.env`, `~/.config/wallpaper-config/wallpaper-cycle.sh` |
