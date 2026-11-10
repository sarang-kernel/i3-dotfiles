---
title: "Home server"
parent: "HP desktop and server"
nav_order: 6
---

# Home server

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


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
