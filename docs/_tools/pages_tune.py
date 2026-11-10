"""Hand-written pages for rog-tune, the scripts section extras, and the ISO section."""
from common import *


def build():
    write("rog-tune/index.md", fm("rog-tune", None, 5, children=True, desc="How the ROG Flow X13 was tuned: parts, dry runs, undo"),
          """# rog-tune

`rog-tune/` is the folder of scripts I used to tune, trim and set up the ROG Flow X13, and that I keep so I can see exactly *what* I changed and put it back.
It started as "why is this laptop so hot and slow" and grew into the installer for my whole desktop.

![The Settings app](../img/settings.png)

## The scripts

| Script | Needs root | What it is |
|---|---|---|
| [`rog-tune.sh`](rog-tune-parts.html) | yes | The **root-side** parts: power saving, kernel and GRUB options, hibernation, the login screen, pacman hooks, services |
| [`rog-lean-session.sh`](lean-session-parts.html) | no | The **user-side** parts: edits my i3, polybar and kitty configs and writes out the helper scripts |
| [Login screen](login-screen.html) | yes (part `greetd`) | The greetd + ReGreet login screen and the helpers the parts install in `/usr/local/lib/rog` |\n| [`rog-snappy.sh`](tools.html#rog-snappysh) | yes | Moves the *Balanced* profile to `balance_performance` so the CPU reacts faster |
| [`rog-report.sh`](tools.html#rog-reportsh) | no | What the machine is spending right now (CPU, RAM per app, dGPU state, heat, clocks) |
| [`rog-clean.sh`](tools.html#rog-cleansh) | no | Throws away regenerable caches |
| [`rog-debloat.sh`](tools.html#rog-debloatsh) | for `--apply` | Lists and removes package bloat |
| [`rog-refresh.sh`](tools.html#rog-refreshsh) | no | Switch the refresh rate by hand |
| [`ferdium-lean.sh`](tools.html#ferdium-leansh) | no | Cuts Ferdium's idle cost |
| [`power-compare.sh`](tools.html#power-comparesh) | no | Measures battery draw per mode and per refresh rate |
| [`vaapi-check.sh`](tools.html#vaapi-checksh) | no | Is hardware video decoding available? |
| [`bt-capture.sh`](tools.html#bt-capturesh) | yes (run through systemd) | Records Bluetooth connection events only |

## The house rules

1. **Dry run first.** Nothing changes until I pass `--apply`.
2. **Every change is undoable**, and the undo is part of the script.
3. **Measure before and after.** `rog-report.sh` and `power-compare.sh` exist so I never apply a "tweak" on faith; several parts are marked opt-in because the gain was not measured.
4. **Small and tagged.** Lines these scripts add carry a `rog-tune` marker so they can be found and removed.

## Where the pieces end up

| Source | Result |
|---|---|
| `rog-tune.sh` parts | Files under `/etc`, `/usr/local/lib/rog`, `/boot/grub`, systemd units; the list per part is on [the parts page](rog-tune-parts.html) |
| `rog-lean-session.sh` parts | `~/.config/i3/config`, `polybar/config.ini`, `kitty/kitty.conf`, `~/.bashrc`, and the scripts in `~/.config/scripts` |
| Backups | `/var/backups/rog-tune/<timestamp>/` (root side), `~/.local/share/rog-tune/*.before` (user side), `/var/backups/rog-restore/` (a pacman restore point before every transaction, `restore` part) |

The restore ISO captures the *result* of all this (see [Restore ISO](../iso/)).
""")

    write("rog-tune/tools.md", fm("The helper tools", "rog-tune", 4), """# The helper tools

{TOC}

## `rog-report.sh`

*What is this machine spending? Run it before and after a change and compare.* `rog-report.sh [seconds]` (default 30) samples `/proc` twice, `seconds` apart, and prints:

- machine busy percentage and the **top 8 apps by CPU and memory**, with Chromium/Electron helper processes grouped under their parent app (and Electron apps named after their app folder). Memory is **PSS** (shared pages split fairly between processes), not RSS.
- the **dGPU's power state** from sysfs only (`control`, `runtime_status`, seconds suspended): it never wakes the NVIDIA GPU, which `nvidia-smi` would.
- heat and fans: `k10temp`, `amdgpu`, `nvme` temperatures, the ASUS fan RPMs, other thermal zones above 25 °C.
- the current display mode, average CPU clock, platform profile and governor.

`notes/baseline.txt` in the repo is one such report from before I tuned anything: the machine was 1.1 % busy but the dGPU had been *active for the whole 4792 s* and the fans were at 5800 / 3700 RPM, which is what started the `gpu` part of rog-tune.

## `rog-clean.sh`

`rog-clean.sh [--apply] [--trash] [--browsers]`: dry run by default, shows sizes. Removes regenerable caches only: Ferdium per-service `Cache`, `Code Cache`, `GPUCache`, service-worker caches (about 5 GB; the apps rebuild them and I stay logged in), and `~/.cache/{pip,pnpm,yay,ms-playwright}`. `--browsers` also clears web caches of Chrome, Firefox, Zen, qutebrowser and the Electron chat apps, **only for apps that are not running**. `--trash` also empties `~/.local/share/Trash`. It refuses to run while Ferdium is open. It never touches logins, cookies or settings.

## `rog-debloat.sh`

`rog-debloat.sh [groups…]` lists what each group would remove with `pacman -Rsp`, sizes included; `sudo … --apply` actually removes after pacman's own confirmation.

| Group | What |
|---|---|
| `safe` (default) | `libinput-gestures` (touchegg does my gestures), the `*-debug` packages of `md-viewer-git` and `yay` |
| `nm` | `networkmanager` and its applet (NetworkManager is disabled; `iwd` does Wi-Fi) |
| `orphans` | Packages nothing depends on any more (`pacman -Qdtq`): look at the list first |
| `fonts` | Several unused big font families (Iosevka, Cascadia, Fira); it greps my configs and warns if one still names those fonts |

## `rog-refresh.sh`

`rog-refresh.sh` shows the panel modes; `rog-refresh.sh 60|120|165` switches now (reverts at the next login). Superseded by `power-watch.sh` and Settings, which handle any rate from 60 to 165 Hz.

## `ferdium-lean.sh`

Trims Ferdium's idle cost by changing four settings in `~/.config/Ferdium/config/settings.json`: spellchecking off, the todo feature off, Sentry telemetry off, and hibernation after 120 s of inactivity per service (services still wake periodically to fetch notifications). `--apply` refuses while Ferdium runs (it rewrites the file on exit), writes a `.before-lean` backup, and `--undo` restores it.

## `power-compare.sh`

*Measure real battery draw.* Unplug first and leave the laptop alone. `power-compare.sh [modes|refresh|all]` switches caffeine on, then for each step waits `SETTLE` seconds (default 45) and averages the battery's power draw over `DUR` seconds (default 120, one sample per 5 s). `modes` = Quiet / Balanced / Performance; `refresh` = a static desktop at 60 / 90 / 120 / 165 Hz in Balanced with the display agent paused. It restores your mode and timers when done and writes `notes/power-compare.txt`.

My results on this laptop:

| Step | Average draw |
|---|---|
| Quiet mode | 5.36 W |
| Balanced | 5.65 W |
| Performance | 7.85 W |
| 60 Hz (static desktop, Balanced) | 5.93 W |
| 90 Hz | 5.94 W |
| 120 Hz | 6.30 W |
| 165 Hz | 6.46 W |

**What I learned from it:** 60 Hz and 90 Hz cost the same, so I run 90 Hz on AC; 120 and 165 Hz cost about 0.4-0.5 W more, so adaptive refresh only drops the rate when it is 110 Hz or more.

## `vaapi-check.sh`

See the [system tools page](../scripts/system.html#vaapi-checksh).

## `bt-capture.sh`

*Records only Bluetooth connection events.* It pipes `btmon -T` through a **whitelist** `grep` (disconnects with reasons, LE connection completes and updates, connection interval/latency, supervision timeout, scanning) so data lines never reach the file: typed keys on a Bluetooth keyboard cannot end up in the log. Run it as a transient unit so it stops by itself:

```bash
sudo systemd-run --unit=bt-capture --property=RuntimeMaxSec=4h ~/rog-tune/bt-capture.sh
```

Output: `/var/tmp/bt-events.log`. I wrote it to catch a Bluetooth keyboard that dropped while typing; the disconnects it recorded carried reason 0x08 (connection timeout). The root cause is not resolved.

## `rog-snappy.sh`

`sudo ~/rog-tune/rog-snappy.sh`. The asusd service sets the *Balanced* profile to the CPU energy preference `balance_power`, which keeps cores at 1.1-2.4 GHz until load has built up: fine on battery, sluggish on the charger. The script backs up `/etc/asusd/asusd.ron` to `asusd.ron.bak-snappy`, changes `profile_balanced_epp: BalancePower` to `BalancePerformance`, restarts `asusd` and also writes `balance_performance` straight into every `energy_performance_preference` file so it applies at once. Quiet keeps its power-saving preference.
Undo: `cp /etc/asusd/asusd.ron.bak-snappy /etc/asusd/asusd.ron && systemctl restart asusd`.
""".replace("{TOC}", TOC))

    write("rog-tune/undo.md", fm("Backups and undo", "rog-tune", 5), """# Backups and undo

{TOC}

## Root side (`rog-tune.sh`)

`--apply` creates `/var/backups/rog-tune/<timestamp>/` containing `files/<absolute path>` (a copy of every file it is about to overwrite), `manifest` (every path it touched), `parts` (which parts ran) and some part-specific lists (`svc`, `hib`). `--undo` restores the **most recent** backup:

1. For each path in the manifest: copy the backed-up file back, or delete the path if it did not exist before.
2. For each part in `parts`, reverse what files cannot: NVIDIA runtime power back to `on`, `sysctl --system`, journald restart, `asusctl battery limit 100`, re-enable stopped services, disable services it enabled (`rog-health.timer`, `ananicy-cpp`, `reflector.timer`, `earlyoom`, hibernate's NVIDIA sleep services), restore PCI power-control values saved in `/run/rog-pm.orig`, reload udev, restart resolved, remount without `lazytime`/`noatime`, `systemctl set-default multi-user.target` (for `dm`), re-enable LightDM and disable greetd (for `greetd`), regenerate GRUB.

Because `--undo` takes the newest backup only, undo after each experiment rather than at the end of a long session.

## User side (`rog-lean-session.sh`)

Before changing a file it saves it to `~/.local/share/rog-tune/` as `i3config.before`, `polybar.ini.before`, `kitty.conf.before`, `bashrc.before`, `picom.conf.before`, `rofi-main.before`, `rofi-power.before`, `wallcycle.before`, `wallcycle-rev.before`, `lock.before`. `--undo` copies them back and removes `created.list` files, autostart stubs with the `rog-tune` marker, the Firefox/Zen `user.js` blocks between `rog-tune` markers, and re-enables things it had disabled (psd, dunst, the automount).

## Pacman restore points

The `restore` part installs a pacman hook (`/etc/pacman.d/hooks/00-rog-restore.hook`) that saves a **restore point before every install, upgrade or removal**: package lists with versions (`versions.txt`), the running kernel (`kernel.txt`), `/etc` (`etc.tar.gz`) and the GRUB config, about 2 MB each, last five kept, in `/var/backups/rog-restore/`. It never blocks pacman. `rog-update.sh --rollback` uses them (see [System tools](../scripts/system.html#rog-updatesh)).

## Backups I keep by hand

After every round of changes I copy the files I am about to change to `~/.local/share/rog-backups/` with a suffix like `.bak30`. These are not used by any script; they are insurance and safe to delete when everything has run for a while.
""".replace("{TOC}", TOC))

    write("rog-tune/login-screen.md", fm("Login screen and installed helpers", "rog-tune", 3), """# Login screen and installed helpers

{TOC}

## The login screen (`greetd` part)

A **greetd + ReGreet** login screen on **VT7**: a GTK4 greeter that shows my wallpaper with a warm amber and chalk look. It runs inside a tiny **sway** (not cage, so the screen can follow the accelerometer, touch included). My `tty1` text login stays untouched as a safety net, and `--undo` re-enables LightDM.

| File (written by the part) | What it is |
|---|---|
| `/etc/greetd/config.toml` | `vt = 7`; the default session is `/usr/local/lib/rog/greeter-start.sh`, run as the `greeter` user |
| `/etc/greetd/regreet.toml` | ReGreet config: background `/usr/share/backgrounds/rog/current` (cover), dark GTK, Papirus-Dark, font Noto Sans 15, reboot/poweroff commands, the greeting *Welcome back*, a clock, and `x11_prefix = ["/usr/local/lib/rog/x11-session.sh"]` |
| `/etc/greetd/regreet.css` | The look: translucent card on the wallpaper, rounded fields with an amber focus ring, an amber *Log in* button, quiet reboot/power-off buttons, a large thin clock |
| `/etc/greetd/sway.conf` | A bare sway: no borders, hidden cursor while typing, `caps:super`, runs `greeter-rotate-sway.sh` and then `regreet`; when regreet exits it stops the rotation helper and exits sway |
| `/usr/local/lib/rog/greeter-start.sh` | Picks the GPU for sway. **Waits up to 15 s** for the AMD driver's card to show an `eDP` panel (never the NVIDIA card, which stays asleep). Only if the driver never appears does it fall back to the boot framebuffer (`simple-framebuffer`); if there is nothing at all it exits 1 |
| `/usr/local/lib/rog/greeter-rotate-sway.sh` | Follows `monitor-sensor --accel` and runs `swaymsg "output * transform N"` for 0, 90, 180, 270 |
| `/usr/local/lib/rog/greeter-brightness.sh` | Run as root before the greeter (`greetd.service.d/rog.conf`, `ExecStartPre=+`): if the brightness is below 30 % it is lifted to 45 %, because a screen left at a few percent looks black. My own level comes back at login (`login-apply.sh`) |
| `/usr/local/lib/rog/x11-session.sh` | `exec startx`: ReGreet hands the chosen X session here, and i3 starts exactly as it does from a text login (through `~/.xinitrc`) |
| `/usr/local/lib/rog/greeter-rotate.sh` | The older, LightDM-era script that did the rotation and brightness lift with `xrandr` (kept in the overlay) |

**Why the 15 s wait matters:** started before the AMD driver takes over, sway opens the early boot framebuffer, which vanishes when the driver loads: the greeter keeps running and accepting keys on a screen that only shows old boot messages. That is what happened when the optional `slimboot` part removed `amdgpu` from the boot image; both are fixed (see [Changes](../changes/)).

The `dm` part is the older variant (LightDM with a rotating login screen and a polkit rule); `greetd` supersedes it.

## Other helpers the parts install in `/usr/local/lib/rog`

| File | Installed by | What it does |
|---|---|---|
| `pm-apply.sh` | `pm` | **PCI runtime power management follows the power source.** On battery every PCI device's `power/control` becomes `auto` and its original value is remembered in `/run/rog-pm.orig`; on AC each goes back to its remembered value. NVIDIA GPUs and the AMD sensor hub (screen rotation) are left alone. Run by a udev rule (`81-rog-pm.rules`) on every plug/unplug and at boot |
| `restore-point.sh` | `restore` | Pacman hook helper: saves `explicit.txt`, `versions.txt`, `etc.tar.gz`, the GRUB config and the kernel version to `/var/backups/rog-restore/<timestamp>/` before a transaction. At most one per 10 minutes, keeps the last five, **never fails the transaction** |
| `health.sh` | `health` | Writes `/var/lib/rog/health.txt` from `smartctl -a /dev/nvme0` (model, overall health, wear, spare capacity, temperature, power-on hours, data written, integrity errors) for Settings → System. Run weekly by `rog-health.timer` |

## System files the parts create (examples)

`/etc/udev/rules.d/80-nvidia-pm.rules` (let the NVIDIA GPU power itself off when idle), `/etc/sysctl.d/90-rog.conf` and `91-rog-net.conf` (dirty-page limits, swappiness, NMI watchdog off, TCP tuning), `/etc/modules-load.d/rog-bbr.conf` (TCP BBR), `/etc/systemd/journald.conf.d/50-rog.conf` (log size cap), `/etc/tmpfiles.d/rog-aspm.conf` and `rog-thp.conf` (PCIe ASPM policy, transparent hugepages `madvise`), `/etc/X11/xorg.conf.d/10-no-nvidia-screen.conf` (`xgpu`), `/etc/xdg/reflector/reflector.conf` (mirror list). Each is listed under its part on the [parts page](rog-tune-parts.html) and in the [file index](../reference/file-index.html).
""".replace("{TOC}", TOC))

    # scripts section extras
    write("scripts/conventions.md", fm("Script conventions", "Scripts", 6), """# Script conventions

{TOC}

Every script follows the same few habits. Knowing them makes any script in this repo easy to read.

## Header comment

The first lines after the shebang say what the script does and how to call it. Lines I added through the installer start with `# rog-tune:`. A script that takes arguments lists them as `#   name  what it does` lines, which the script often prints itself for a bad argument (`sed -n '2,8p' "$0"`).

## Settings through `settings.env`

Scripts never keep settings of their own. They source `~/.config/rog/settings.env` (`[[ -r … ]] && . …`) and use defaults for anything missing (`${LOCK_AC:-10}`), so a fresh install works with no file at all. The Settings app is the only writer. See the [settings reference](settings-reference.html).

## One copy of every long-running script

Anything started by i3's `exec_always` (it runs again on every reload) first **kills its previous copy**: it writes its pid to `$XDG_RUNTIME_DIR/<name>.pid` and on start checks `/proc/<pid>/cmdline` before killing. `display-agent.py` goes further and kills *every* other instance of itself.

## State lives in files, not memory

Small flag files in `$XDG_RUNTIME_DIR` (gone at logout) and `$XDG_STATE_HOME` (kept): `caffeine`, `autocaffeine.on`, `autoquiet.on`, `adaptive.low`, `cinema.on`, `cinema.hz`, `camera.on`, `display-agent.pause`, `autorotate.lock`, `nightlight/mode`. Scripts coordinate by creating and testing these; `ls $XDG_RUNTIME_DIR` shows what is active.

## Event driven, not polling

`upower --monitor`, `pactl subscribe`, `i3-msg -t subscribe`, `inotify`, `xinput test-xi2` or a blocking `read -t` on a private fifo wake the scripts up. The few that sleep (`nightlight.sh daemon`, `display-agent.py`) sleep until the *earliest moment* something could change. The bar's brightness and microphone indicators are the proof: no process is spawned every second.

## Look things up at run time

The panel is `eDP-1` or `eDP-2` depending on which GPU driver registers first, so scripts run `xrandr --current | awk '/^eDP[^ ]* connected/{…}'` instead of hard-coding it. (`rog-lean-session.sh`'s optional `hz60` part is the one place that still does.)

## Silent by design

No popups, no sounds, no OSD bars: the notification daemon is parked and the bar shows state. The exceptions are the alarm window and the power menu, which are windows I asked for.

## Safe edits

Scripts that edit a file with `sed -i` (accent colour in polybar and i3, Settings toggles) use exact patterns and **skip the write when nothing changes**, so they do not trigger a bar restart or an i3 reload for no reason. Never `sed -i` a symlink (see [Compositor](../i3/compositor.html)).

## Testing hooks

`ROG_PS` (a fake power-supply directory), `ROG_DRY=1` (print what `display_apply` would do), `ROG_ROOT`/`ROG_SYSFS` (rog-tune), `ROG_BK` (rog-lean-session backups) let me test logic without touching hardware.

## Checking a script

```bash
bash -n script.sh           # syntax
shellcheck script.sh        # if installed
python3 -m py_compile script.py
```
""".replace("{TOC}", TOC))

    write("scripts/settings-app.md", fm("The Settings app", "Scripts", 2), """# The Settings app

{TOC}

`scripts/settings.py` is a GNOME-Settings-style window (**GTK4 + libadwaita**): a category sidebar on the left, grouped rows on the right, and **changes apply at once**, no Apply button. Open it with **Super+,**, or type "settings" in Spotlight.

![Settings, Display page](../img/settings.png)

It is **not** a resident process: it starts on demand (`rog-ui.sh settings` focuses an existing window, otherwise starts one) and leaves nothing in memory when closed. Window class `RogSettings`, default size 1280×800.
`settings.py --backup` opens only the backup folder chooser (Spotlight's "Back up to hp-server…").

Search: type in the box above the sidebar (or `Ctrl+F`) to search *every row title and description*; picking a result jumps to the page and focuses the row. `Esc` clears the search, then closes the window.

## Pages and what they change

| Page | Rows | What happens when I change them |
|---|---|---|
| **Display** | Night tint (mode, warmth 2700-6000 K, from/until hour), Refresh rate (AC, battery: 60-165 Hz), Adaptive refresh (on/off, idle seconds, idle rate), Cinema mode (on/off, film rate), Effects (blur on AC, dim inactive windows) | Writes `settings.env`, then `nightlight.sh reapply` or `power-watch.sh display|refresh`; the effects rows edit `picom-ac.conf` and send picom `SIGUSR1` |
| **Power & Performance** | Performance mode (AC, battery), Low battery (auto-Quiet on/off, at N %), Keeping the screen on (caffeine switch, automatic caffeine), Lock and screen-off minutes (AC, battery), **Fans** (firmware default / quieter / cooler) | `power-watch.sh display|timers|autoquiet`, `caffeine.sh`, `autocaffeine.sh`; fan curves go to `asusctl fan-curve` for each profile |
| **Battery** | Read-only: charge, health (full vs design energy), cycles, power draw, time left/to full, voltage, model | Refreshes every 3 s while open |
| **Keyboard & Mouse** | Tap to click, natural scrolling, ignore touchpad while typing, pointer speed, key repeat delay and rate | `input-apply.sh` |
| **Windows & Terminal** | Focus follows mouse, border thickness, terminal opacity, freeze rotation, tablet mode | Edits `i3/config` with a regex and runs `i3-msg reload`; opacity edits `kitty.conf` and signals kitty; the two switches call `autorotate.sh lock` / `tablet.sh` |
| **Sound** | Output device, volume, mute; input device, volume, mute; **volume per app** | `pactl` (default sink/source, volumes up to 150 %, per-sink-input volume); refreshes every 4 s while open |
| **Wallpaper** | Day and night start hours, change automatically every N minutes, *Change it now* | `wallpaper-timer.sh`, `wallpaper-cycle.sh` |
| **Top Bar** | Which modules show (volume, brightness, battery, memory, CPU, Wi-Fi, microphone, camera), workspace app icons, active-workspace marker (box or line), number weight and size | Rewrites `modules-right`, `font-1` and marker lines in `polybar/config.ini`, then `polybar-msg cmd restart` |
| **Startup Apps** | A switch for every XDG autostart entry | Writes (or removes) a `Hidden=true` stub in `~/.config/autostart`; effective at next login. i3's own `exec` lines are not listed |
| **Spotlight** | Transparency, recents, deep-search folders, info on the clipboard history and shortcuts | `SPOT_OPACITY`, `SPOT_RECENTS`, `~/.config/spotlight/roots` |
| **General** | Theme (light, dark, schedule), accent (amber, wallpaper, custom + colour button), start with the microphone muted, **Export / Import settings**, alarm sound, keep screenshot files | `accent.sh`, `settings.env`; export writes a `.tar.gz` of `settings.env`, `aliases`, `roots`, `sync.list` |
| **System** | Disk free (system, home), memory, uptime, kernel, **SSD health** (from `/var/lib/rog/health.txt`, weekly) | Read-only |
| **Backup** | *Choose folders and back up…* and *Mirror deletions* | Writes `~/.config/spotlight/sync.list`, starts `sync-server.sh` in a floating kitty |

## How a change is applied

`setv(key, value)` re-reads `settings.env`, sets the key and saves (so concurrent writers, like `power-mode.sh`, are not overwritten). Sliders wait 350 ms after you stop moving them before applying. Saving also recomputes `NIGHT_GAMMA` from `NIGHT_K`.
The look (light/dark/accent) is applied with libadwaita's colour scheme (`FORCE_DARK`/`FORCE_LIGHT`) and an `@define-color` accent override.

## Fan curves

The two custom curves (CPU and GPU, eight points each, temperature °C → fan %) are in `FAN_CURVES`: *quiet* stays at 0 % up to 55 °C (CPU) / 60 °C (GPU) and reaches 100 % at 90 °C; *cool* spins early (10 % at 40 °C) and also reaches 100 % at 90 °C. Every curve ends at full speed by 90 °C, and *Firmware default* hands control back to the machine. Applied to the Quiet, Balanced and Performance profiles through `asusctl fan-curve`.

## Export and import

*Export settings* saves `~/.config/rog/settings.env`, `~/.config/spotlight/aliases`, `roots` and `sync.list` into `rog-settings-YYYYMMDD.tar.gz`. *Import settings* only accepts those four names from the archive and then re-applies power, night tint and input. Use it on a fresh install.

## Reference

All 39 keys: [`settings.env` reference](settings-reference.html).
""".replace("{TOC}", TOC))

    # ISO
    write("iso/index.md", fm("Restore ISO", None, 6, children=True, desc="A bootable Arch ISO that rebuilds the laptop offline"),
          """# Restore ISO

My "everything is on fire, press this" button. A bootable Arch ISO that **rebuilds the ROG Flow X13 completely offline**: the packages (at the versions I had), `/etc`, the services, my configs, my dev tools. The stable `linux` kernel only (no LTS). My own files (Documents, Development, Media, browser profiles …) are not in it, and the default mode never touches them.

The recipe is in the repo under `iso/`; the ISO itself (about 9.5 GB) is too big for GitHub.

## How I use it

1. Write it to a USB stick of 16 GB or more: `sudo dd if=rog-restore-*.iso of=/dev/sdX bs=4M status=progress oflag=sync`
2. Boot it (UEFI), run `rog-restore`, pick **1) Rebuild, keep /home**. It formats only the boot and root partitions; `/home` stays exactly as it was.
3. Reboot. Login screen, hibernation (swap file and resume offset are recalculated), the NVIDIA module and the tuning come back by themselves. After a restore run `sudo pacman -Syu` once Wi-Fi is up.

## Pages

| Page | What you get |
|---|---|
| [What is inside](contents.html) | The four parts of the image and what is deliberately left out |
| [Building it](build.html) | `prepare.sh`, `build.sh`, disk space, the AUR repack |
| [rog-restore](restore.html) | Every mode and option of the installer, step by step |
| [Testing](testing.html) | The QEMU test harness and the self-test |
| [Plan B: recover from GitHub](recovery.html) | When both local ISOs are gone |
| [Security](security.html) | What is in the local ISO and what is published |
""")

    write("iso/contents.md", fm("What is inside", "Restore ISO", 1), """# What is inside

{TOC}

| Part | In the image | Content |
|---|---|---|
| Package repository | `/opt/rog/repo` | Every package at the version I had installed: **941 from the Arch repos and 10 from the AUR** (counts at the last build; `iso/lists/native.txt` and `aur.txt` are the current lists) |
| `overlay.tar.zst` | `/opt/rog/` | My `/etc` changes (every packaged file marked *modified* and every file nobody owns), which services are enabled, `/usr/local`, the wallpaper in `/usr/share/backgrounds/rog`, `/var/lib/rog`. No secrets |
| `home-config.tar.zst` | `/opt/rog/` | `~/.config`, shell and X dotfiles, `~/.local`, Rust, nvm, Neovim data, `rog-tune`, my dotfiles clones |
| `secrets.tar.zst` | `/opt/rog/` | ssh and gnupg keys, SSH host keys, Wi-Fi passwords, Bluetooth pairings, password hashes. **Only in local ISOs, never published** |
| `snapshot.info` | `/opt/rog/` | Machine facts: snapshot date, root/boot/home UUIDs, user name and uid, time zone, swap and root sizes |
| `offline.conf` | `/opt/rog/` | A pacman config pointing at the local repo with signature checking off (the packages were already verified when downloaded) |

AUR packages are **repacked from the files that are actually installed** (`iso/tools/repack-installed.py` rebuilds a `.pkg.tar.zst` from `/var/lib/pacman/local` metadata), because rebuilding them later is a gamble (old Chrome versions vanish from Google's servers).

## Left out on purpose

zathura, btop, yazi (and `linux-lts`), each with the packages only they needed (`lists/removed.txt` is the exact list); browser and Electron profiles (Chrome, Zen, Discord, Ferdium, Teams), caches, `~/.cargo/registry` and the pnpm store. Those belong to my file backup.

## The lists (`iso/lists`)

| File | Content |
|---|---|
| `native.txt`, `aur.txt` | What gets installed |
| `explicit-all.txt`, `explicit-native.txt` | Which packages I installed on purpose (the rest are marked *as dependencies* again after the restore, so `pacman -Qe` stays short) |
| `native-all.txt` | All native packages including the removed ones |
| `removed.txt` | The left-out set |
""".replace("{TOC}", TOC))

    write("iso/build.md", fm("Building it", "Restore ISO", 2), """# Building it

{TOC}

```bash
./prepare.sh         # as me: downloads the repository (~7 GB), repacks the AUR packages, bundles my home config
sudo ./build.sh      # collects the root-only state and builds the ISO into out/ (needs ~45 GB free)
./test-qemu.sh fresh && ./test-qemu.sh rebuild    # boots it in a VM and runs the whole restore (needs /dev/kvm)
./publish.sh         # stages the recipe (no secrets) in the dotfiles clone and scans it
```

## `prepare.sh` (normal user)

1. **Package lists**: copies the pacman database to `work/db`, writes a private `pacman.conf`, syncs, then computes `removed.txt` (what `pacman -Rsp` would remove for btop, yazi, zathura, zathura-pdf-poppler, linux-lts, linux-lts-headers) and the lists `native`, `aur` (foreign packages without the `-debug` leftover), `explicit-all`.
2. **Downloads** every native package into `work/repo` with `fakeroot pacman -Sw` (resumes).
3. **AUR**: `tools/repack-installed.py` rebuilds each AUR package from the installed files into `work/aur`, copied to the repo.
4. **Repository database**: `repo-add` creates `rogrepo.db.tar.zst`; it checks that the number of package files covers every name.
5. **My configs**: `home-config.tar.zst` (zstd, a list of includes and a long list of excludes for browser profiles, caches, `btop`/`yazi`/`zathura` config) and `secrets-home.tar` (`.ssh`, `.gnupg`, `.bash_history`).
6. **Machine facts** → `work/snapshot.info`.

## `build.sh` (root)

1. Installs `archiso`, `qemu` and OVMF **from the files prepared earlier** (no database refresh, so no partial upgrade).
2. **Root-only state**: `pacman -Qii` gives every file marked `[modified]`, `find /etc` minus the files pacman owns gives the unowned ones; an exclusion regex drops machine-specific and secret paths. **Assertions** make the build fail instead of silently producing an incomplete backup: `/etc/pacman.conf`, `/etc/mkinitcpio.conf`, `/etc/default/grub`, `/etc/hostname`, `/etc/locale.gen` and a sudoers rule must be in the overlay, and no secret-looking path (`ssh_host`, `shadow`, `.psk`, `iwd`, `bluetooth`, `system-connections`) may be in the *public* overlay list.
3. Secrets are collected separately into `secrets.tar.zst` (SSH host keys, iwd and Bluetooth state, NetworkManager connections, my and root's password hashes, plus ssh/gnupg from `secrets-home.tar`).
4. **Profile**: copies archiso's `releng` profile, overlays `profile-overlay/` (`profiledef.sh`, a motd, the `rog-test-live.service`), puts the repository in `airootfs/opt/rog/repo` with **hard links** (no second copy), and `rog-restore` and `rog-test-live` in `/usr/local/bin`. The ISO label is `ROG_RESTORE_YYYYMM`.
5. `mkarchiso` builds the ISO (15-25 minutes, about 40 GB temporarily); the result gets mode 600 and a `.sha256`.

## Disk and time

Needs about 45 GB free; `work/` holds the repository (~7 GB), tool packages and, after testing, VM disks (delete `work/vm` when done: about 34 GB, regenerated by `test-qemu.sh`).
""".replace("{TOC}", TOC))

    write("iso/restore.md", fm("rog-restore", "Restore ISO", 3), """# `rog-restore`

{TOC}

The installer on the ISO. Run as root (the live ISO logs in as root).

```text
rog-restore                       interactive (asks before anything is erased)
--mode rebuild|fresh|devices      rebuild = format boot+root, KEEP /home (default when the old partitions are found)
                                  fresh   = erase a whole disk (--disk /dev/nvme0n1), new layout, empty /home
                                  devices = I name the partitions (--esp --root [--home])
--home-mode restore|stage|skip    how to treat my configs/dev tools from the snapshot
--yes                             no questions (used by the automatic test)
--test                            test run in a virtual machine
```

## Modes

| Mode | What it formats | `/home` |
|---|---|---|
| **rebuild** (1) | Only the boot (FAT32) and root (ext4) partitions, found by the UUIDs in `snapshot.info` | Kept exactly as it is |
| **fresh** (2) | A whole disk: 1 GB ESP, `ROOT_GB` GB root, the rest as `/home`. Refuses the ISO's own medium. You must type the disk name | New and empty |
| **devices** | The partitions you name | The one you name, or none |

Before formatting it asks you to type `ERASE` (rebuild) or the disk name (fresh).

## `--home-mode`

- `restore` (default on an empty or fresh `/home`): configs and dev tools are unpacked straight into `/home/<user>`, and the ssh/gnupg secrets with them.
- `stage` (default when `/home` already has files): everything goes to `~/.rog-snapshot`, **nothing is overwritten**; I copy what I want.
- `skip`: no home snapshot.

## What it does, in order

1. **Pick the target** (above). Old UUIDs are **reused** (`mkfs.ext4 -U`, `mkfs.fat -i`) when no other device carries them, so the next restore still recognises the machine.
2. **Partition / format** and mount (`noatime,lazytime`).
3. **Swap file**: `mkswap --file` of `SWAP_GB` (18 GB by default), because hibernation needs it.
4. **Packages**: `pacstrap -C offline.conf -K -M` of `native.txt` plus `aur.txt` from the ISO (a few minutes; DKMS builds the NVIDIA module at the end). Then `pacman -D --asdeps` and `--asexplicit` restore my install reasons from `explicit-all.txt`, so only what I installed myself is "explicit". The package cache is emptied afterwards (the packages stay on the ISO).
5. **System state**: extracts `overlay.tar.zst` (`--keep-directory-symlink`), writes `fstab` with `genfstab -U` (adds the swap line), sets the time zone.
6. **Hibernation**: reads the swap file's physical offset with `filefrag` and rewrites `resume=UUID=…` and `resume_offset=…` in `/etc/default/grub` (and `RESUME_OFFSET` in the initcpio config if present); `GRUB_DEFAULT=0`.
7. **User and passwords**: creates my group and user with the same uid, adds `wheel`, puts the `greeter` user in `video`, generates locales, sets the clock, and installs the **password hashes** from the secrets (or asks for a new password if none).
8. **Secrets**: SSH host keys, Wi-Fi (iwd) and Bluetooth state go back to `/etc/ssh`, `/var/lib/iwd`, `/var/lib/bluetooth`.
9. **Boot**: `mkinitcpio -P`, `grub-install --target=x86_64-efi --bootloader-id=Arch --removable`, `grub-mkconfig`. Writes `/etc/rog-restore-info` with the date and snapshot.
10. **Checks** (printed `ok` / `FAIL`): stable kernel and no LTS; amdgpu in the boot image; the resume hook; a GRUB entry for linux with the right resume offset; the bootloader on the ESP; empty package cache; no LTS packages; greetd enabled; fstab has root, boot and swap; sudo rule for me; install reasons restored (fewer than 400 explicit packages).
11. Kills the `gpg-agent` that `pacman-key` leaves behind and unmounts (lazily if something still holds on), then offers to reboot.

## After the first boot

Run `sudo pacman -Syu` once Wi-Fi works (the new system has no package databases until it can reach a mirror).
""".replace("{TOC}", TOC))

    write("iso/testing.md", fm("Testing", "Restore ISO", 4), """# Testing

{TOC}

I do not trust a backup I have not restored. `test-qemu.sh` boots the real ISO in a virtual machine and runs the real `rog-restore`.

```bash
./test-qemu.sh fresh      # blank disk -> fresh install -> first-boot self-test (also creates a sentinel file in /home)
./test-qemu.sh rebuild    # same disk -> rebuild keeping /home -> self-test (the sentinel must survive)
PATCH=0 ./test-qemu.sh fresh   # use exactly what is baked into the ISO (the final check of a build)
```

Needs `qemu-base`, `edk2-ovmf` and `/dev/kvm`. The VM gets 4 GB RAM and 6 CPUs at low priority (`nice`, `ionice`); logs are `work/vm/<stage>-install.log` and `<stage>-boot.log`.

## How the VM test works

- It extracts the ISO's kernel and initramfs and boots them directly with `-kernel/-initrd`, with `rog_test=<stage>` on the command line and the serial console on `ttyS0`.
- `rog-test-live.service` (in the ISO, `ConditionKernelCommandLine=rog_test`, so it **never runs on real hardware**) calls `rog-test-live`, which reads the scenario from `/proc/cmdline` and runs `rog-restore --test --yes --mode fresh --disk /dev/vda --home-mode restore` (scenario `fresh`) or `rog-restore --test --yes --mode rebuild --home-mode stage` (scenario `rebuild`), then powers off. `--test` uses a 1 GB swap file and a 40 GB root, gives the user the password `rogtest`, installs `selftest.sh` as a service on the new system and puts the serial console on the kernel command line.
- **`PATCH=1`** (the default) boots a small extra disk with the newest `rog-restore`, `offline.conf` and `selftest.sh`, so fixes can be tested without rebuilding the 9.5 GB ISO. `PATCH=0` tests the baked-in versions.

## The self-test (`selftest.sh`)

Runs once on the first boot of a test restore, prints to the serial log and powers off: kernel version, `/boot` files, system state and **failed units**, enabled units, package counts (total, explicit, foreign, LTS), `pacman -Qkq` problems, cache size, root usage, users and the greeter's groups, swap, command line, amdgpu in the boot image, the **sentinel** (created, or *survived*), the contents of `/home`, the staged snapshot, a check of six key files (`i3/config`, `.bashrc`, `.rustup`, `.nvm`, the ssh key, gnupg), `/etc` facts, SSH host key presence, iwd and Bluetooth state, sudo rules, greetd and the display-manager link, DKMS status.

## What the tests found (and fixed)

Five real bugs: the install reasons of packages, an unmount that failed because a `gpg-agent` stayed alive, two wrong self-checks, and signature checking (*keyring is not writable*) which is why `offline.conf` has `SigLevel Never`. The final baked image passed 12 of 12 checks in a fresh install. The keep-`/home` rebuild passed earlier with the same script.
""".replace("{TOC}", TOC))

    write("iso/recovery.md", fm("Plan B: recover from GitHub", "Restore ISO", 5), """# Plan B: rebuilding from the repository only

**Not tested end to end.** The ISO is the tested path; this is for the day both local ISO copies are gone. My secrets (ssh keys, Wi-Fi passwords, Bluetooth pairings, password hashes) are deliberately not in the repository, so those have to be recreated by hand.

1. Install a minimal Arch (`archinstall`, or the wiki guide) with the **`linux`** kernel, a 1 GB FAT32 boot partition at `/boot` and an ext4 root. Keep or create `/home`. Make myself user `sarang` (uid 1000) in `wheel`.
2. As root, install the packages: `pacman -S --needed - < iso/lists/native.txt` (it already leaves out zathura, btop, yazi and the LTS kernel). Then, as me: `yay -S --needed $(cat iso/lists/aur.txt)`. These come out at current versions, not the ones I had.
3. Put the system configuration back: `sudo tar -C / --keep-directory-symlink -xpf <(tar -C iso/overlay -cf - .)`. Git does not keep file modes, so check permissions afterwards. Then fix `/etc/default/grub` (new root UUID, a new `resume_offset` from `filefrag -v /swapfile`, `GRUB_DEFAULT=0`), recreate `/swapfile`, run `mkinitcpio -P`, `grub-install --removable --efi-directory=/boot` and `grub-mkconfig -o /boot/grub/grub.cfg`.
   My sudo and polkit rules are not in the overlay on purpose: add `sarang ALL=(ALL) ALL` in `/etc/sudoers.d/` myself.
4. Configs: clone the dotfiles repo and run its `install.sh`, then clone my `nvim` repo.

The published `iso/overlay/` holds 72 files (mkinitcpio, modprobe, sysctl, udev, tmpfiles, systemd, texmf, lightdm, iwd defaults, a few `/usr/local` scripts, the wallpaper, …); see the [file index](../reference/file-index.html).
""")

    write("iso/security.md", fm("Security", "Restore ISO", 6), """# Security

{TOC}

## What is where

| Copy | Contains secrets? |
|---|---|
| **Local ISO** (on the laptop and on the home server) | **Yes, unencrypted:** ssh and gnupg keys, SSH host keys, Wi-Fi passwords, Bluetooth pairings, password hashes. Treat the ISO file like a private key. It is mode 600 |
| **GitHub recipe** (`iso/` in the dotfiles repo) | No. `publish.sh` strips sudoers, polkit, ssh, NetworkManager files and lock files, then runs `scan-secrets.sh` (it fails the publish if a key, token, password or similar string is found) |

Passphrase-encrypting the local ISOs is possible but not done; ask for it if you want it.

## The publish checks

- `build.sh` refuses to build if a secret-looking path is in the public overlay list.
- `publish.sh` copies the recipe (scripts, lists, `profile-overlay`, `tools`, the README files) into the dotfiles clone, unpacks the overlay (deleting any file over 1 MB, which is the wallpaper copy), then **removes** `etc/sudoers` and `sudoers.d`, `etc/polkit-1`, `etc/ssh`, `etc/NetworkManager`, `git-filter-repo` (a third-party tool), `.pwd.lock` and `health.txt`, and runs `scan-secrets.sh` on the result. It does not commit; I review and commit by hand.
- `scan-secrets.sh DIR` fails if any file contains a private-key header, a code-hosting, cloud or chat token, a Wi-Fi passphrase or pre-shared-key line, a password assignment or a password hash, or if any file *name* looks like a key or credential store (private keys, certificates, `known_hosts`, SSH host keys, `shadow*`, GitHub CLI hosts files, password-manager databases, anything under `.ssh`, `.gnupg`, the iwd or Bluetooth state folders, NetworkManager connections, or shell history).
- Commits to the public repo carry no attribution lines (my own rule for my repositories).

## After a restore

Passwords and keys return from the secrets bundle, so the first boot is already "me". If the ISO was ever copied somewhere untrusted, rotate the SSH keys and Wi-Fi passwords.
""".replace("{TOC}", TOC))


if __name__ == "__main__":
    build()
