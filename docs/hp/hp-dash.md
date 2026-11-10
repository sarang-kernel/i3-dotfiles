---
title: "hp-dash"
parent: "HP desktop and server"
nav_order: 7
---

# hp-dash

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


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
