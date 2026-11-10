"""Hand-written pages for the HP section (Hyprland desktop, home server, hp-dash)."""
from common import *
import gen_hp

P = "HP desktop and server"


def build():
    nbinds, nscripts, rice_rows = gen_hp.build()
    write("hp/index.md", fm(P, None, 8, children=True, desc="My HP EliteBook: Hyprland desktop and home server"),
          """# The HP: Hyprland desktop and home server

The HP EliteBook 840 G1 (Core i5-4300U, 15 GB RAM, a 2013 laptop) is my **home server**: it serves Jellyfin, Audiobookshelf, Calibre-Web, Immich and a dashboard, mostly over Tailscale, with an external USB drive for media. It is also a normal laptop with a **Hyprland** desktop in the same warm look as the i3 one.

> The HP's configuration lives in `~/.config/hypr` (and `~/.config/quickshell`, `~/.local/share/hp-dash`). Unlike my i3 setup it is **not in a git repository yet**, so this section is generated from the files on the machine itself; the file paths are the real ones.

## Pages

| Page | What you get |
|---|---|
| [Hyprland setup](hyprland.html) | The Lua config files one by one, the session start, the terminals |
| [Keybindings](keybindings.html) | Every bind with its description (generated) |
| [Theming](theming.html) | Wallpaper-driven colours, theme packs, light/dark |
| [Swappable shell](shell.html) | Waybar, Quickshell or DMS: three shells, one desktop |
| [Home server](server.html) | `rice status`, `server.conf`, ambient checks, backups, maintenance mode |
| [hp-dash](hp-dash.html) | My browser control center on port 9100: user guide, security model, API |
| [Boot and server tuning](tuning.html) | `server-tune.sh`, `hp-boot-tune.sh`, the flaky USB drive, the boot pile-up |
| [The `rice` command and tools](tools.html) | The CLI and the script reference |
| [Script reference](script-reference.html) | Every script with its header (generated) |

## At a glance

| | |
|---|---|
| Compositor | Hyprland (Lua config, validated with `Hyprland --verify-config`) |
| Panel | 1600×900, scale 1 |
| Shells | `classic` (waybar + swaync + swayosd), `hypr` (my Quickshell shell), `dms` |
| Terminal | foot server + footclient (about 20 MB for all windows), kitty as the fallback (software GL on this iGPU) |
| Theme | Catppuccin Mocha, or generated from the wallpaper with matugen |
| Network | iwd + systemd-networkd, Tailscale |
| Remote | SSH, hp-dash (browser), optional wayvnc on the Tailscale address only |
""")

    write("hp/hyprland.md", fm("Hyprland setup", P, 1), """# Hyprland setup

{TOC}

Hyprland 0.55+ moved to a **Lua** configuration (hyprlang is being dropped). `~/.config/hypr/hyprland.lua` is only the entry point; each concern is a file in `conf/`. Validate any edit without restarting:

```bash
Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
```

(`Super+Shift+C` reloads with that validation built in.)

## Install and start

```bash
~/.config/hypr/install.sh      # one sudo pacman -Syu --needed … of the official packages (list in packages.txt)
~/.config/hypr/doctor.sh       # checks dependencies and validates the config
~/.config/hypr/report.sh       # on a problem: versions, config errors, logs, which shell parts are up -> ~/.cache/hypr/
start-hyprland                 # from a tty
```

`~/.bash_profile` and `~/.xinitrc` were deliberately left alone, so `startx` still gives the old i3 session. Optional autostart on tty1 (a line for `~/.bash_profile`, not `exec`, so a failed session drops back to the shell with the error visible; `touch ~/.no-hyprland` opts out). With greetd autologin (see [tuning](tuning.html)) the machine signs in by itself and locks the session at once.

## Files

| File | What it configures |
|---|---|
| `hyprland.lua` | Entry point: sets `package.path` and requires the files below in order |
| `conf/env.lua` | Environment: `XDG_CURRENT_DESKTOP=Hyprland`, Wayland-first toolkits (`GDK_BACKEND=wayland,x11`, `QT_QPA_PLATFORM=wayland;xcb`, `MOZ_ENABLE_WAYLAND`, Electron ozone hint), capitaine cursors at 24, `LIBVA_DRIVER_NAME=i965` for the Haswell iGPU, the ibus + mozc input method, `FILEMANAGER=thunar` and `TERMINAL=…/term.sh` |
| `conf/monitors.lua` | Panel `eDP-1` at its preferred mode, scale 1; any other display lands to the right at its preferred mode; notifications when one is connected or removed |
| `conf/look.lua` | Gaps 4/10, border 2 with a two-colour gradient, rounding 12 (squircle-ish), dim inactive 10 %, shadows, **2-pass kawase blur**, dwindle (default), master and scrolling layouts. Tuned for a Haswell iGPU: modest shadows, no looping effects |
| `conf/animations.lua` | Bezier and spring curves; windows spring (`glide`), popin for new windows, slide-fade workspaces. `borderangle` is off on purpose (it would redraw every frame) |
| `conf/input.lua` | US layout with `caps:super`, repeat 38/s after 280 ms, num lock on, touchpad natural scroll + tap + drag + disable-while-typing, gestures (3-finger swipe workspaces; Super + 3-finger down closes; 4-finger up scratchpad, down float; Super pinch zoom) |
| `conf/binds.lua` | All keybindings ([generated table](keybindings.html)) |
| `conf/rules.lua` | Window rules: suppress maximize events, fix XWayland drag focus, translucent terminals (`opacity 0.93 0.86`), floating utilities and dialogs, TUI popups, the drop-down terminal, picture-in-picture, and more |
| `conf/autostart.lua` | Session services, once per compositor start |
| `conf/colors.lua`, `conf/palette.lua` | **Generated** colours (see [Theming](theming.html)): do not edit by hand |
| `conf/user.lua` | Look presets from the settings hub (zen mode, transparency, gaps) |
| `conf/eco.lua` | Battery-saver overrides; **must be required last** |
| `hypridle.conf`, `hyprlock.conf`, `hyprsunset.conf` | Idle chain, lock screen (blurred live screenshot, avatar), night-light schedule. `hypridle.conf` has **no suspend-on-battery rule on purpose**, so a power cut does not take the server offline |
| `server.conf` | Which services count as "the server" |
| `webapps.conf` | `name|url` lines for web-app windows (`Super+Alt+B`) |
| `shaders/*.frag` | Screen shaders: `grayscale`, `deuteranopia`, `protanopia`, `tritanopia` (colour-blind simulation), `eink`, `paper`, `sepia`, `invert`, `redlight`, `crt`, `vignette` |
| `kitty/` | `kitty.conf` and generated `colors.conf` |
| `shell/` | Shell integration: `rice.bash` (prompt, fzf, man colours, eza, zoxide), `colors.sh`, `vt-palette.sh`, completion |
| `theme/` | The theme engine (see [Theming](theming.html)) |
| `system/` | Root-side tools (boot theme, server tuning, ssh lock-down, sudo window) |
| `scripts/` | Everything else; see [Script reference](script-reference.html) |

## What starts with the session (`conf/autostart.lua`)

On `hyprland.start`: import the Wayland environment into systemd and D-Bus, start the portals after a second (`portals.sh`) and `hyprpolkitagent`, set GTK/icon/cursor settings (`theme-init.sh`), start `awww-daemon` and the first wallpaper, start the **shell** (`shell.sh start`), `hypridle` and `hyprsunset`, the clipboard history recorders (`wl-paste --watch cliphist store`, text and image), `ibus-daemon`, **`power-watch.sh`** (eco mode on unplug) and **`ambient.sh`** (wallpaper timer, automatic light/dark, resource budget, server checks), and the `foot --server`. With `RICE_AUTOLOGIN` set it locks the session four seconds after start.

## Eco mode

`scripts/eco.sh toggle|on|off|auto-on|auto-off|status` (`Super+F2`). While the flag `~/.cache/hypr/eco` exists, `conf/eco.lua` switches off animations, dimming, blur and shadows. **Manual** eco is only ever turned off by me; **automatic** eco is set by `power-watch.sh` when the charger is unplugged and cleared on plug-in. The governor in `ambient.sh` can also turn it on (reason `governor`) when the shell uses too much CPU.

## Terminals

`scripts/term.sh` starts `footclient` against a single `foot --server` if foot is installed (one 20 MB process for every window, CPU-rendered), otherwise kitty. **kitty needs software GL on this laptop:** Hyprland on the Haswell iGPU advertises no ARGB8888 dmabuf format, so kitty's hardware EGL aborts (*Failed to find a suitable EGLConfig*). `scripts/kitty.sh` sets `LIBGL_ALWAYS_SOFTWARE=1` for kitty only; `touch ~/.config/hypr/kitty-hw` switches back to hardware GL after a Mesa or Hyprland fix.

## Notes

- Waybar 0.15's workspace module is display-only under a Lua config (clicks cannot dispatch), so scrolling over the window title or the clock switches workspaces; the `hypr` Quickshell shell has clickable workspaces.
- Haswell tip: if animations stutter on battery, raise `INTEL_GPU_MIN_FREQ_ON_BAT` in `/etc/tlp.conf` (for example to 500).
- Network is iwd and systemd-networkd, so the bar opens `impala` (Wi-Fi), `bluetui` and `wiremix` as floating TUIs (`scripts/tui.sh`, window class `tui-popup`).
- `.pacnew` care: keep my own `mkinitcpio.conf` (the new default drops the consolefont hooks) and `sshd_config` (the new default drops the hardening).
""".replace("{TOC}", TOC))

    write("hp/theming.md", fm("Theming", P, 4), """# Theming

{TOC}

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
""".replace("{TOC}", TOC))

    write("hp/shell.md", fm("Swappable shell", P, 5), """# Swappable shell

{TOC}

The compositor, windows and theme never change; only the bar, notifications and on-screen display do. Switch with `Super+I → Shell`, or `scripts/shell.sh use classic|hypr|dms`. It is remembered across logins; anything not installed falls back to `classic`.

| Profile | What runs | Measured here |
|---|---|---|
| `classic` | waybar, swaync, swayosd | about 106 MiB |
| `hypr` | **one Quickshell process** (`~/.config/quickshell/hypr`) | about 130 MiB, 0.04 % CPU idle |
| `dms` | Dank Material Shell (`dms run`) | about 484 MiB |

## `shell.sh`

```text
shell.sh use classic|hypr|dms     switch now and remember it
shell.sh start | stop | status | profile
shell.sh dashboard | overview | launcher | wallpapers | power | notif | dnd [on|off|toggle] | refresh | theme   routed to the running shell
```

It also works from an ssh or tty shell: it finds the running session itself.

## What the `hypr` shell adds

- **Clickable workspaces** (the classic bar cannot do that under a Lua config).
- `Super+A` **dashboard**, `Super+O` **overview** (drag windows between workspaces), `Super+D` **launcher** (apps, open windows, actions, `2+2`, `?search`, `>command`).
- Panels are built on open and freed on close.

Qt's **software renderer is deliberate**: on this GPU GL surfaces lose their alpha (the same cause as the kitty crash) and the software path takes less memory. The cost is no live window thumbnails; the overview shows a one-shot capture of the current workspace and icon + title cards for the rest.

## Warnings

- **Never run `dms setup` or `caelestia install`**: they replace `hyprland.lua`. `dms run` alone only adds `hypr/dms/` and colour files, and picks its own colours from its own wallpaper.
- If the shell crashes, `ambient.sh` restarts it within a minute; after three failed restarts it falls back to `classic`.

## The resource budget (10 %)

The rice measures itself: `scripts/rice-meter.py` sums **PSS memory** and CPU of the shell processes only (not your apps) as a share of the machine (`rice meter`, also the bar's stats drawer). `ambient.sh` governs it: more than 10 % CPU for 3 minutes drops the GPU-heavy effects (eco mode, reason *governor*), and 10 calm minutes restore them. Everything added since is either a native compositor rule (smart gaps, workspace hue ring, zen mode) or a static shader (GPU only, no time uniform), so nothing forces extra frames.
""".replace("{TOC}", TOC))

    write("hp/server.md", fm("Home server", P, 6), """# Home server

{TOC}

The HP serves Jellyfin, Audiobookshelf, Calibre-Web, Immich and a dashboard, mostly over Tailscale. The services bind to the Tailscale address or localhost, and the **media lives on an external USB drive** mounted at `~/Media` (the SSD only holds the system and `/home`).

## See the state: `rice status`

`rice status [json]` shows services, Tailscale, the media drive, heat, and the battery acting as a **UPS** (mains or battery; a power cut raises a problem within 2 minutes), plus pending package updates and how old the package list is. SSH logins print one line per problem and nothing when all is well. The bar shows a red server chip and the dashboard has a server card.

## `server.conf`: what counts as "the server"

One entry per line: a system unit (`sshd`, `tailscaled`, `jellyfin`, `audiobookshelf`, `calibre-web`, `docker`), `user:<unit>` for a systemd **user** unit (`user:dashboard`), or `http:<name> <url>` for something only reachable over the network (Immich, a Docker container). Edit it to change what `rice status` and the checks watch.

## `ambient.sh`: the checker

Started with the session. Every **2 minutes** it checks the server and **notifies when the *set* of problems changes** (so a problem that stays does not repeat). While the panel is off it samples once a minute, and wallpaper and light/dark changes wait until it is back on. It also runs the wallpaper timer, the automatic light/dark switch (07:00 / 19:00 when Appearance is *Auto*) and the resource budget governor.

## Maintenance mode

`rice maintenance on [hours]` (1-12, default 2) | `off`: while I am working on the server it does not alert about what I am knowingly breaking. Problems are still recorded; anything still wrong when the window ends is reported then. Also a switch in hp-dash.

## Other server tools

- `system/server-tune.sh` holds the root-side fixes (dry run, `--apply`, `--undo`, restarts none of my services); see [Boot and server tuning](tuning.html).
- `rice vnc on|off`: a remote desktop (wayvnc) **on the Tailscale address only**, started on demand; there is no VNC password, anyone on my tailnet can connect (the same trust as the other services). Needs a logged-in session.
- `system/ssh-lan.sh try|keep|off|status`: lets SSH in only from the home network, Tailscale and localhost (the port is closed to the internet even if the router forwards it). `try` reverts itself after 3 minutes unless I `keep` it, in case it locks me out; established connections are never cut.
- `system/sudo-window.sh <minutes>`: a **time-limited passwordless sudo** (writes `/etc/sudoers.d/90-rice-window` after a `visudo` check and a timer that deletes it); only used deliberately.
- `server-tune.sh wol` (opt-in): Wake-on-LAN on the wired port (the BIOS must allow it too).
- `rice backup`: what the newest backup holds. `rice logs <service>`: follow a service's log (anything in `server.conf`).
- `scripts/server-status.py` (268 lines) is the engine behind `rice status`.

## Healthcheck, backups, timers

These pre-date this documentation and are not part of `~/.config/hypr`, so I only describe how I observe them:

- `media-server-healthcheck.timer` runs `media-server-healthcheck.service` every 5 minutes (script `/usr/local/bin/media-server-healthcheck.sh`): for each check (disks, `~/Media` mount, Tailscale, and the Jellyfin, Audiobookshelf and Immich services) it verifies, **attempts a repair if broken** (up to 3 consecutive attempts, then it escalates), re-verifies, and **mails only on a state change** (so a self-healed problem produces one "HEALED" note, not PROBLEM + RECOVERED). State is in `/var/lib/media-server-healthcheck/state`.
- `media-hdd-recover.service` runs when the media drive (re)appears: fsck, mount, restart the dependent services. A udev rule (`ACTION=="add"`, matching the drive's UUID) starts it; the matching `remove` rule starts `media-hdd-disconnect.service`.
- `media-server-backup.timer` (about 00:20 every night), `rice-backup-verify.timer`, `rice-smart.timer`, `rice-ssh-lan-refresh.timer` and `shadow.timer`.
- `hermes-morning.timer` is my morning-brief workflow; its service has a boot-time gate (see [tuning](tuning.html)).
""".replace("{TOC}", TOC))

    write("hp/hp-dash.md", fm("hp-dash", P, 7), """# hp-dash

{TOC}

**A browser control center for the HP**, in `~/.local/share/hp-dash`. One login, six tabs, reachable from my phone or iPad on the tailnet or through an ssh tunnel. It is one Python file (`server.py`, about 1000 lines: standard library plus `psutil`) and plain JavaScript (`static/app.js`, no build step) with vendored xterm.js, noVNC and a Nerd Font.

## Getting in

| From | How |
|---|---|
| One of my own devices on the tailnet | `http://<the HP's tailnet name>:9100` |
| Plain ssh, no tailnet | `ssh -L 9100:127.0.0.1:9100 me@hp`, then `http://localhost:9100` |
| The laptop itself | `http://localhost:9100` |
| A terminal only | `ssh me@hp` |

The port is `9100` (`config.json`). Run the service with `systemctl --user enable --now hp-dash` after linking `hp-dash.service` into `~/.config/systemd/user/`; check it with `python3 ~/.local/share/hp-dash/server.py status`. `KillMode=process` is deliberate: the terminal's tmux lives in the service's cgroup, and restarting the dashboard must not kill my shells.

## The six tabs

| Tab | What I get |
|---|---|
| **Overview** | CPU, memory, temperatures, battery, disks, network graphs (sparklines), the devices on my tailnet, the busiest programs (with a quit button) and links to the media apps |
| **Desktop** | The real Hyprland screen with mouse, keyboard and clipboard in both directions: `wayvnc` on a **Unix socket** (no VNC port) proxied through a WebSocket to noVNC. |
| **Terminal** | A real shell in **tmux** session `dash`, over a WebSocket (xterm.js). Closing the tab does not kill what is running |
| **Files** | Browse, upload (drag and drop, streamed to disk, space checked), download (HTTP ranges), edit small text files (under 2 MB), make folders, rename, move to the trash. Only below the roots in `config.json` (default: my home folder) |
| **Services** | My user systemd units (restart/stop), the server health check, and journal logs for the units in `log_units` |
| **Controls** | Wake/sleep the screen, lock, volume, brightness, media keys, open a link or show a message on the laptop, caffeine, battery saver (eco), maintenance mode, screenshot to the laptop's clipboard, suspend / reboot / power off |

Reboot, power off and suspend need me to **type the action's name** to confirm; on this machine they additionally need a polkit rule from a service (see [tuning](tuning.html)), so those three buttons are greyed out until I add it.

## Security model

In the order a request meets it:

1. **It listens only on `127.0.0.1` and the machine's Tailscale address.** Never the LAN, never the internet.
2. A request from the tailnet must come from a device that belongs to one of `allowed_logins` (checked with `tailscale whois`). Devices that other people have on my tailnet are refused with a 403 *before* they see the login page.
3. The `Host` header must be one of the machine's own names (blocks DNS rebinding).
4. Everything except the login page needs a **session cookie** from a successful password login (`HttpOnly`, `SameSite=Strict`, 12 hours by default). The password is stored only as a salted **PBKDF2** hash in `~/.config/hp-dash/auth.json` (mode 600). **Five wrong passwords lock that address out for 15 minutes**; a wrong password also costs 0.8 s.
5. Anything that changes something needs a custom header (`X-HP-Dash`) **and** a same-origin `Origin`, so another website cannot poke it from my browser.

Other decisions: the Desktop tab's VNC server has no network port at all; the Services tab refuses units that are part of the session (`dbus`, `pipewire`, `wireplumber`, portals, the polkit agent, `gnome-keyring`, `gpg-agent`, `ssh-agent`, `systemd-*`, `app-*`, `session-*`) and the dashboard itself; files are served with a sandbox header and HTML/SVG/JavaScript is delivered as plain text so opening one of my own files cannot run it as a web page; killing a process is limited to my own processes (never pid 1 or the server).

## Commands

```text
server.py serve      run the dashboard (what the systemd user unit does)
server.py init       create the login password (random, shown once)
server.py passwd     set the login password yourself
server.py status     is it up, and where it listens
```

## Configuration (`~/.config/hp-dash/config.json`)

| Key | Default | Meaning |
|---|---|---|
| `port` | `9100` | Listening port (`HP_DASH_PORT` overrides it for tests) |
| `allowed_logins` | my Tailscale login | Whose devices may connect over the tailnet |
| `session_hours` | `12` | Session cookie lifetime |
| `roots` | `["~"]` | The only folders the Files tab can touch (paths are resolved with `realpath`, so symlinks cannot escape) |
| `log_units` | sshd, tailscaled, jellyfin, audiobookshelf, calibre-web, docker, greetd, NetworkManager, systemd-networkd | Units whose logs the Services tab can show |

## HTTP API

All calls (except login) need the session cookie; state-changing calls need the `X-HP-Dash` header.

| Call | What it does |
|---|---|
| `POST /api/login` | Password login (rate limited) |
| `POST /api/logout` | End the session |
| `GET /api/me` | User, host name and the caller's address |
| `GET /api/overview` | CPU, memory, disks, temperatures, battery, network, processes, tailnet devices, links |
| `GET /api/services`, `POST /api/service` | List user units; `start`/`stop`/`restart` one (never a protected one) |
| `GET /api/logs?scope=system&unit=…&n=…` (or `scope=user`) | Journal lines (plain text) |
| `GET /api/controls`, `POST /api/control` | State of the controls; run an action (`wake`, `screen_off`, `lock`, `caffeine`, `eco`, `volume`, `mute`, `brightness`, `play-pause`, `next`, `previous`, `open_url`, `notify`, `maintenance`, `screenshot_to_clipboard`, `suspend`, `reboot`, `poweroff`) |
| `POST /api/proc` | Terminate (or `KILL`) one of my processes |
| `GET/POST /api/desktop` | Is the screen share on; start or stop `wayvnc` |
| `GET /api/screenshot` | A JPEG of the screen (`grim`) |
| `GET/POST /api/clipboard` | Read or set the laptop's clipboard (`wl-paste` / `wl-copy`) |
| `GET /api/fs/list`, `/get`, `/text` | List a folder, download/stream a file, read a text file |
| `POST /api/fs/write`, `/mkdir`, `/rename`, `/trash`; `PUT /api/fs/put` | Save a text file, make a folder, rename, move to the trash, upload |
| `GET /ws/term`, `/ws/vnc` | WebSocket: the tmux terminal; the VNC proxy |
| `GET /`, `/static/…`, `/favicon.svg`, `/login.js` | The page and its files |

## Files

`server.py`, `static/` (`index.html`, `app.js`, `app.css`, `favicon.svg`, `vendor/` with xterm.js, noVNC and the JetBrains Mono Nerd Font), `hp-dash.service`, `README.md`.
""".replace("{TOC}", TOC))

    write("hp/tuning.md", fm("Boot and server tuning", P, 8), """# Boot and server tuning

{TOC}

## What a boot looks like

On the last measured boot the HP got to the Hyprland desktop about **13 s after the kernel started** (greetd autologin at about 8 s), after about 10 s of firmware and bootloader. For the next ~3 minutes several background jobs compete for the two cores of the i5-4300U: a persistent catch-up timer (my morning workflow), the media health check, the media drive's recovery and fsck, and services starting (Jellyfin, Immich's containers). That is why the machine *feels* slow for a while even though the login came quickly.

## `hp-boot-tune.sh`

`sudo ~/hp-boot-tune.sh` (root, writes systemd drop-ins and a GRUB tweak; **restarts nothing**, so running services stay up):

| Change | Why |
|---|---|
| `media-server-healthcheck.service.d/boot-grace.conf`: `ExecCondition` that requires 7 minutes of uptime, plus `Nice=15`, `IOSchedulingClass=idle`, `CPUSchedulingPolicy=idle` | The health check used to run 2 minutes after boot, find Jellyfin, Immich and Audiobookshelf still starting (the CPU needs 3+ minutes) and **restart them mid-startup** |
| `hermes-morning.service.d/boot-grace.conf`: wait for 7 minutes of uptime, then for DNS (`getent hosts github.com`, up to 150 s), idle CPU/IO priority | The catch-up timer fired immediately after every boot, before the network was up, and burned about 3 minutes of CPU and disk on failing fetches |
| `/etc/default/grub`: `GRUB_TIMEOUT=2`, `GRUB_TIMEOUT_STYLE=hidden`, then `grub-mkconfig` | A visible 10 s menu at every boot with only one thing to boot. Hold Shift or press Esc during the 2 s to get the menu back; the old file is kept as `grub.bak-boot-tune` |

Undo: delete the two `*.d` folders and restore the GRUB file, then `systemctl daemon-reload` and `grub-mkconfig`.

## `server-tune.sh`

`sudo ~/.config/hypr/system/server-tune.sh [parts]` (dry run by default; `--apply`, `--undo`; backs up every file; restarts none of my services). Default parts: `boot hdd sysctl journal immich health`; `wol` and `watchdog` are opt-in.

| Part | What it does |
|---|---|
| `boot` | A Tailscale outage no longer holds up the boot or the nightly backup. calibre-web and audiobookshelf still wait for it (they bind to the Tailscale address), but TLP and everything else start without it |
| `hdd` | `media-hdd-recover` waits for the boot-time fsck instead of failing against a busy drive |
| `sysctl` | zram-friendly swapping, smaller write bursts to the USB drive, reboot 30 s after a kernel panic |
| `journal` | Caps the system log at 500 MB |
| `immich` | Starts Immich once Tailscale is up (its web port binds the Tailscale address, which does not exist early in boot) |
| `health` | Daily root checks: every backup file readable, each drive's SMART health (installs smartmontools) |
| `wol` (opt-in) | Wake-on-LAN on the wired port (the BIOS must allow it) |
| `watchdog` (opt-in) | Hardware watchdog: reboot by itself if the machine hangs (from the next boot) |

## The USB media drive that keeps disconnecting

The external drive (a Toshiba disk in a JMicron JMS583 USB bridge on a USB 3 port) **disconnected 10 times between Nov 5 and 7 and 19 times between Nov 7 and 10**, each time unmounting `~/Media` and taking the libraries away from Jellyfin and friends. USB autosuspend is already off for it (a udev rule and a TLP denylist), the xHCI controller is not runtime-suspended, and I found no correlation with AC events beyond one case, so the cause is not known. The kernel log shows `USB disconnect` followed by `device offline error`, then ext4 shutting the filesystem down.
Practical advice: a different USB port, a powered hub or a shorter cable first. The healthcheck and `media-hdd-recover` then fsck and remount and restart the services, but each disconnect is still an outage.

## Lag snapshot: `lag-now`

`Super+Shift+F12` (Hyprland and i3 both): appends a one-second snapshot to `~/lag-notes.log`. See the [i3 scripts page](../scripts/session.html#lag-now) for what it records. Nothing runs in the background.
""".replace("{TOC}", TOC))

    rows = [("`rice status [json]`", "Server health: services, Tailscale, the media drive, heat, the battery as a UPS"),
            ("`rice meter`", "What the desktop itself costs against the 10 % budget"),
            ("`rice shell`, `rice shell classic`, `rice shell hypr`, `rice shell dms`", "Show or switch the desktop shell"),
            ("`rice wake`, `rice lock`", "Switch the panel on; lock the session"),
            ("`rice shot [file]`", "Screenshot (the panel must be on)"),
            ("`rice logs <service>`", "Follow a service's log (anything in `server.conf`)"),
            ("`rice backup`", "What the newest backup holds"),
            ("`rice remind <10m or 18:30> <text>`, `rice remind list`, `rice remind clear`", "Reminders (each one is a transient systemd timer)"),
            ("`rice webapp [name]`", "Open a web app in its own window"),
            ("`rice maintenance on [hours]`, `rice maintenance off`", "Quiet the server alerts while I work on it"),
            ("`rice vnc`, `rice vnc on`, `rice vnc off`", "Remote desktop over Tailscale only (needs wayvnc and a logged-in session)"),
            ("`rice snapshot [label]`, `rice snapshots`, `rice rollback [id]`", "Save, list and restore the desktop configuration"),
            ("`rice update [--check] [--aur]`, `rice downgrade <package>`", "Snapshot, upgrade and report; go back one cached version of a package"),
            ("`rice doctor [--fix]`", "Check for known problems; optionally repair the safe ones"),
            ("`rice msg <text>`", "Show a notification on the desktop")]
    write("hp/tools.md", fm("The `rice` command and tools", P, 9), """# The `rice` command and tools

{TOC}

`rice` (`~/.config/hypr/scripts/rice`) is one command for the desktop **and** the server from any terminal, including over SSH: it finds the running Hyprland session by itself (`XDG_RUNTIME_DIR`, the newest `HYPRLAND_INSTANCE_SIGNATURE`, the `wayland-N` socket).

""" + table(["Command", "What it does"], rows) + """

## More tools

- **Theme packs:** `theme.sh pack tokyo-night|gruvbox|nord|rose-pine|kanagawa|everforest`.
- **Safety net:** `rice snapshot` / `rice snapshots` / `rice rollback [id]` for the desktop config (ext4 has no Btrfs snapshots; keeps the newest 20); `rice update [--check] [--aur]` snapshots, upgrades and reports what needs a restart, new `.pacnew` files and server health; `rice downgrade <package>` goes back one cached version; `rice doctor [--fix]` checks for known problems and repairs the safe ones.
- **Desktop:** `Super+Ctrl+R` reminders (`rice remind 10m text`; each is a transient systemd timer, so they cost nothing while waiting), `Super+Alt+B` web apps (`webapps.conf`), `Super+Ctrl+Print` OCR a region, `Super+Alt+Print` decode a QR code, `Super+Backspace` transparency toggle, `Super+Shift+Backspace` gaps toggle, `Super+K` keybinds, `Super+Alt+N` act on the latest notification, `Super+Ctrl+N` dismiss it.
- **Screen recording:** `Super+Print` toggles `wf-recorder` (full), `Super+Shift+Print` (region); `record.sh status` prints Waybar JSON.
- **Screenshots:** `Print` full, `Shift+Print` region, `Ctrl+Print` window, `Alt+Print` region then annotate (satty); saved to `~/Pictures` with the same names as the i3 ones, copied to the clipboard, with a notification preview.

The complete list of scripts with their header comments is on the [script reference page](script-reference.html).
""".replace("{TOC}", TOC))


if __name__ == "__main__":
    build()
