"""Hand-written explanations for each script. The generator adds the mechanical facts (header, settings read, files touched, tools used)."""

PROSE = {}

PROSE["power-watch.sh"] = """
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
"""

PROSE["power-mode.sh"] = """
Quiet, Balanced or Performance for **the power source I am on right now**. The choice is stored in `settings.env` as `MODE_AC` or `MODE_BAT`, so plugging in or out later restores the mode I chose for that source.

- **Quiet**: power-saver CPU profile (capped near 4 GHz, quiet fans), 60 Hz, no blur, no dimming.
- **Balanced**: everyday. On AC it also means blur and 90 Hz.
- **Performance**: CPU and fans unrestricted (louder, hotter).

Defaults: Balanced on AC, Quiet on battery. `cycle` rotates through the three (that is `Super+Alt+M`). Choosing a mode on purpose deletes the low-battery override flag, because a deliberate choice beats the automatic Quiet.
It writes the key with `sed` (or appends it) and then runs `power-watch.sh display`. Spotlight ("performance mode …") and the Settings app change exactly the same thing.
"""

PROSE["display-agent.py"] = """
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
"""

PROSE["nightlight.sh"] = """
A warm night tint through the display's gamma ramp: `xrandr --output <panel> --gamma R:G:B`. No extra package, no popup.

- Modes are stored in `$XDG_STATE_HOME/nightlight/mode`: `auto` (follow the schedule), `on`, `off`.
- The schedule is `NIGHT_START`-`NIGHT_END` (hours; defaults 19 and 7).
- The tint is `NIGHT_GAMMA`, which the Settings app derives from the *Warmth* slider (`NIGHT_K`, 2700-6000 K) with a black-body approximation (`gamma_for` in `settings.py`). The fallback is `1.0:0.81:0.65` (about 4000 K).
- `toggle` flips what is currently on or off; `auto` goes back to the schedule; `reapply` re-applies the current state (the rotation script and `power-watch.sh` call it, because a rotation or a mode-set can reset the ramp).
- `daemon` re-evaluates every 5 minutes (or immediately when something writes to its private fifo) so the tint switches at the scheduled hour without cron.
"""

PROSE["autorotate.sh"] = """
Panel, touchscreen and pen rotate together with the accelerometer. It runs `monitor-sensor --accel` and maps each orientation to an `xrandr --rotate` value plus a *Coordinate Transformation Matrix* for every touchscreen and stylus
(`normal`, `left-up` → `left`, `right-up` → `right`, `bottom-up` → `inverted`). It then calls `nightlight.sh reapply`, because a rotation can reset the colour ramp.

Details that took some debugging and are worth knowing:

- `monitor-sensor` stays alive and silent when the sensor claim is refused (it only warns on stderr), and a claim made before the session is fully active is refused. So the script reads stderr too, and when it sees *Failed to claim* it kills `monitor-sensor`, waits (2 s, doubling up to 30 s) and starts it again. Rotation never depends on a single attempt at login.
- `CURRENT` is only updated after `xrandr` succeeded, so a refused rotation is retried.
- The panel name is looked up at run time instead of hard-coding `eDP-1`.
- `autorotate.sh lock` toggles `$XDG_STATE_HOME/autorotate.lock`; while it exists, nothing rotates (`Super+Shift+O`, or Settings → Windows & Terminal → *Freeze rotation*). Tablet mode removes the lock, because tablets rotate.
- It keeps a pid file and kills the previous copy on start, so an i3 restart does not stack watchers.
"""

PROSE["input-apply.sh"] = """
Applies touchpad, pointer and keyboard settings from `settings.env`: key repeat (`xset r rate KEY_DELAY KEY_RATE`, bell off), and for every input device that has the libinput properties: tapping, natural scrolling, disable-while-typing and pointer acceleration speed.
It runs on i3 `exec_always` (so reloads re-apply), and the Settings app runs it whenever one of those rows changes.
"""

PROSE["accent.sh"] = """
The accent colour has to reach two places Spotlight and Settings cannot touch themselves: the polybar *active workspace* colour (`mauve = …` in `polybar/config.ini`) and the focused-window border (`client.focused` in `i3/config`).
Modes (`ACCENT_MODE`): `amber` (`#e0a458`), `custom` (`ACCENT_HEX`) and `wallpaper`. For `wallpaper` mode, `accent.sh wallpaper` samples the current wallpaper at 64×64 with ImageMagick, scores every pixel by saturation and by closeness to mid-lightness, and takes the winner as the accent (cached in `~/.cache/accent-wallpaper`).
If the colour did not change it exits without restarting anything; otherwise it edits the two files with `sed`, restarts polybar (`polybar-msg cmd restart`) and reloads i3.
"""

PROSE["wallpaper-timer.sh"] = """
Creates (or removes) the automatic wallpaper timer. Every call first stops `rog-wallpaper.timer`; when `WALL_EVERY` is above zero it starts a transient systemd user timer with `systemd-run --user --unit=rog-wallpaper --on-active=Nm --on-unit-active=Nm`
that runs `wallpaper-cycle.sh`, passing `DISPLAY`, `XAUTHORITY` and the D-Bus address along. Set from Settings → Wallpaper.
"""

PROSE["caffeine.sh"] = """
Manual caffeine. `on` creates `$XDG_STATE_HOME/caffeine` and runs `xset s off -dpms` (no auto-lock and no screen blanking; closing the lid still suspends, and `Super+Shift+L` still locks). `off` removes the file and asks `power-watch.sh timers` to restore the timers for the current power source.
`status` prints `on`, `auto` (autocaffeine is holding the screen) or `off`.
"""

PROSE["autocaffeine.sh"] = """
Caffeine that switches itself on. The screen stays on and unlocked while a window is **fullscreen on the visible workspace** (video, presentations) or **an app is recording from the microphone** (calls); music does not count.
It is event driven: `pactl subscribe` for source-output events and an i3 subscription for fullscreen/close/workspace events feed one private fifo, and `update` re-evaluates once per burst of events. The microphone check ignores `peak`, `pavucontrol`, `volume`, `polybar` and `mission` (volume meters and monitors).
The state is the file `$XDG_RUNTIME_DIR/autocaffeine.on`. Set `AUTOCAFFEINE=0` in Settings → Power & Performance to disable it. The manual toggle works independently.
"""

PROSE["pin.sh"] = """
Pins the focused window: `floating enable, sticky enable, resize set 900 560, move position center`. Run it again and it does `sticky disable, floating disable`, putting the window back into the tiling tree. Sticky means it follows me to every workspace, which is how a video or a note stays visible.
"""

PROSE["tablet.sh"] = """
Tablet mode is an on-screen keyboard (`onboard`) docked at the bottom, which pops up when a text field gets focus (`org.onboard.auto-show`). It is **off at every login** (nothing starts it) and needs `sudo pacman -S onboard`. Turning it on also removes the autorotate lock, because tablets rotate.
"""

PROSE["scratch.sh"] = """
My notepad. It opens `~/Documents/scratch.md` in a floating kitty with class `scratch` running Neovim with three extra options: autosave on `TextChanged`, `TextChangedI` and `InsertLeave`, soft-wrap at word boundaries, and the cursor on the last line.
The i3 rule `for_window [class="^scratch$"] floating enable, resize set 1100 760, move position center` makes it a centred window. Running the script while the notepad is open kills it, so `Super+N` is a toggle. It exists because gedit crashed on this machine; see [Changes](../changes/).
"""

PROSE["shot.sh"] = """
Screenshots with `scrot`. Everything goes to the clipboard as a PNG (`xclip -t image/png`), so it pastes straight into browsers, chat and editors; unless `SHOT_SAVE=0` it is also saved as `~/Pictures/screenshot_YYYY-MM-DD_HH-MM-SS.png`.
Modes: `full`, `area` (select with the mouse; Esc cancels quietly), `window` (focused), `area-clip` (clipboard only, never a file). It is deliberately silent: no popup, no sound.
"""

PROSE["ocr.sh"] = """
Select an area with `scrot -s`, run `tesseract` (English, page segmentation mode 6), trim trailing spaces and put the text on the clipboard. Needs `tesseract` and `tesseract-data-eng`.
"""

PROSE["osd.sh"] = """
Volume, microphone and brightness actions, silent (the bar shows the state). Volume uses `pactl` in 5 % steps and unmutes when raising. Brightness uses `brightnessctl` and, if present, the `nvidia_wmi_ec_backlight` device (the one that really dims this panel).
After a brightness change it saves the value to `~/.local/state/rog/brightness`; `login-apply.sh` restores it on the next login (the greeter raises a nearly-dark screen so the login box stays readable).
`up1` and `down1` are 1 % steps (the bar's scroll wheel uses them).
"""

PROSE["keys.sh"] = """
`Super+F1` / `Super+/`. A small Python program inside the script reads `i3/config`, joins continued lines, expands `set` variables, prettifies key names (`Mod4` → `Super`, `XF86MonBrightnessUp` → *Brightness Up* …), summarises each command, and prints one aligned line per `bindsym` (resize-mode ones are prefixed `[resize]`).
The list goes into `rofi -dmenu` with the Catppuccin theme at a big font, so typing filters it. It always reflects the real config because it parses it every time.
"""

PROSE["sysmon.sh"] = """
Opens the first GUI task monitor it finds (`missioncenter`, `resources`, `gnome-system-monitor`) and otherwise runs `btop` inside kitty with class `sysmon`. Bound to `Super+Shift+Esc`, and clicking CPU or memory in the bar runs it too.
"""

PROSE["camera.sh"] = """
The polybar custom/ipc module for the *camera in use* chip: prints a red camera glyph and `cam` while `$XDG_RUNTIME_DIR/camera.on` exists (the display agent maintains that file) and nothing otherwise.
"""

PROSE["power-menu.py"] = """
`Super+Esc`. A GTK3 window of six big tiles: Lock, Log out, Sleep, Hibernate, Restart, Shut down. `h`/`l`, arrows or Tab move, `1`-`6` pick, Enter runs, Esc or `q` closes. Lock and Sleep run at once; the other four need a **second Enter** (the tile turns solid and the line below says what will happen).
Hibernate is only offered when `resume=` is on the kernel command line. The header line shows host, uptime and battery. The look follows `APPEARANCE` (light, dark, schedule) and the accent colour. Pressing the key while the menu is open closes it (it looks for another copy of itself and sends it SIGTERM).
Window class `RogPower` (see the `for_window` rule). Commands: `lock.sh`, `i3-msg exit`, `systemctl suspend|hibernate|reboot|poweroff`.
"""

PROSE["alarm.py"] = """
The window a Spotlight timer or reminder shows when it rings: a centred card (`RogAlarm`) with the message, which stays until I press Enter or Esc; `S` snoozes for 5 minutes (it schedules itself again with `systemd-run --user --on-active=300s`, and records the alarm in `alarms.json` so Spotlight can list it).
A sound plays up to four times (`alarm-clock-elapsed.oga` through `paplay`) unless `ALARM_SOUND=0`. It is started by `systemd-run --user` from Spotlight, with `DISPLAY`/`XAUTHORITY`/bus variables passed along.
"""

PROSE["login-apply.sh"] = """
Runs **once per login** (an `exec`, not `exec_always`, so reloads do not repeat it). If `MIC_MUTE_LOGIN=1` it mutes the default microphone after 3 s. It then restores the brightness I last chose from `~/.local/state/rog/brightness`, because the greeter may have raised a dark screen so the login box could be read.
"""

PROSE["pen-setup.sh"] = """
The ASUS stylus (`ELAN9008:00 04F3:40FD Stylus`) and touchscreen get mapped to the internal panel with `xinput map-to-output`, the stylus is enabled, a linear pressure curve is set with `xsetwacom` (if installed), the buttons are mapped (button 2 → right click, button 3 → middle click) and the touchscreen ignores touches while typing.
The panel name is looked up (`eDP-1` or `eDP-2`). If the pen is not present it logs *Pen not detected* and exits with 1.
"""

PROSE["toggle-touchpad.sh"] = """
`XF86TouchpadToggle`. Finds the touchpad's xinput id, reads `Device Enabled` and flips it with `xinput enable|disable`.
"""

PROSE["lag-now"] = """
Press `Super+Shift+F12` when the machine lags. It appends a one-second snapshot to `~/lag-notes.log`: the kernel's pressure-stall averages (10 s / 60 s / 300 s) for CPU, IO and memory, the busiest processes, anything waiting on disk, biggest memory users, RAM and swap, CPU frequency, governor and energy preference, thermal-throttle counts and temperatures, GPU load, the refresh rate, recent kernel warnings and recently started or failed services.
Nothing runs in the background: the kernel keeps the pressure averages itself, which is why a snapshot taken *after* a stall still shows it. I added it instead of a recorder because a recorder is one more thing that runs all the time.
"""

PROSE["rog-update.sh"] = """
The careful way to update. It reads the **Arch Linux news** feed (`https://archlinux.org/feeds/news/`) and shows every item published since my last full system upgrade (found in `/var/log/pacman.log`), flagging titles that mention *manual intervention*, *requires*, *breaking* or *before upgrading*. Only if I agree does it run `sudo pacman -Syu`.
Afterwards it tells me which restore point was saved before the update and counts new `.pacnew` files.

`rog-update.sh --rollback` lists the restore points that the `restore` part of [rog-tune](../rog-tune/rog-tune-parts.html) saves before every pacman transaction (`/var/backups/rog-restore/*`), and reinstalls the older package versions from the pacman cache (`pacman -U`). It never touches `/etc`; the old `/etc` is in `etc.tar.gz` inside the restore point.
Spotlight offers both as actions ("System update", "Roll back the last update").
"""

PROSE["sync-server.sh"] = """
Manual backup of my research folders to the home server (`hp-server:Media/rog-backup/`, the external drive) over SSH with `rsync`. It runs only when I ask and **never deletes anything there** unless I turned on *Mirror deletions* (`BACKUP_MIRROR=1`, capped at 500 deletions per run).
Folders come from `~/.config/spotlight/sync.list` (written by the Settings backup dialog; default `~/notes` and `~/Documents`). Safety checks: it refuses unless the server answers over SSH, and it refuses unless `~/Media` on the server is a real mount point, otherwise a copy would silently fill the server's SSD.
Caches (`node_modules`, `__pycache__`, `.venv`, `site-packages`, `.cache`) are skipped. `-n` is a dry run. On success it records the time in `~/.local/state/spotlight/last-backup`, which Spotlight uses for the *"Your last backup was N days ago"* hint (shown after 7 days).
"""

PROSE["login-bg.sh"] = """
Wallpaper hook (the wallpaper scripts call it). It does three things: it starts `accent.sh wallpaper` in the background (accent "from the wallpaper"); it builds the lock-screen image (`~/.cache/lock-bg.png`: the wallpaper scaled and cropped to 2560×1600, blurred, darkened 35 %; `i3lock` only reads PNG, once per wallpaper); and, if `/usr/share/backgrounds/rog` is writable, copies the wallpaper to `/usr/share/backgrounds/rog/current` so the greetd/ReGreet login screen (which runs as another user and cannot read `~`) shows the same picture.
"""

PROSE["vaapi-check.sh"] = """
Read-only check for hardware video decoding: runs `vainfo` (driver `radeonsi` unless `LIBVA_DRIVER_NAME` is set) and lists H.264, HEVC, VP9 and AV1 profiles, then shows where VA-API is switched on (`chrome-flags.conf`, Firefox-family `user.js`). Needs `libva-utils`. The `vaapi` part of `rog-lean-session.sh` turns it on.
"""

PROSE["wallpaper-cycle.sh"] = """
Next wallpaper (`Super+Y`). Picks the folder by time of day: `~/Pictures/wallpapers/day` between `WALL_DAY_START` (7) and `WALL_NIGHT_START` (19), `.../night` otherwise (or the base folder if day/night do not both exist). It keeps a per-folder file list that is rebuilt only when a hash of the file names changes, and a rotating index, then applies the image with `feh --bg-scale`, saves its path in `~/.cache/current_wallpaper` and starts `login-bg.sh` for the lock screen, login screen and accent.
The reverse script is identical except that it steps the index backwards.
"""

PROSE["rg-pre.sh"] = """
The `--pre` helper that lets Spotlight's deep search look inside PDFs: `ripgrep` calls it for every `*.pdf`; it extracts the text once with `pdftotext -layout` and caches it under `~/.cache/spotlight/pdf/` keyed by path and modification time, then prints the cached text. The first deep search through many PDFs is slow; later ones are fast.
"""

PROSE["rog-ui.sh"] = """
The client for the resident Spotlight process. `spotlight`, `apps`, `clip` write the command to `$XDG_RUNTIME_DIR/rog-ui.fifo` (the daemon is started first if it is not running); `start` / `restart` / `quit` manage the process (pid in `rog-ui.pid`); `settings` focuses the Settings window if it exists or starts `settings.py`; `backup` starts the backup chooser.
Settings is deliberately **not** resident: it starts on demand and leaves nothing in memory.
"""

PROSE["spotlight.py"] = "See the [Spotlight section](../spotlight/) for the full documentation of this program."
PROSE["settings.py"] = "See [The Settings app](settings-app.html)."
