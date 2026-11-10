---
title: "System, backup and update tools"
parent: "Scripts"
nav_order: 5
---

# System, backup and update tools

Scripts that touch the wider system: updates and rollback, the backup to the home server, wallpaper plumbing and the client for Spotlight's resident process.

Each script has a short explanation, then a block of **facts that are extracted from the script itself** (settings it reads, programs it calls, files it touches), so the list stays honest when the script changes. Scripts live in `~/.config/scripts` (the repo's `scripts/` folder); `install.sh` copies them there.

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


## Scripts on this page

- [`rog-update.sh`](#rog-updatesh)
- [`sync-server.sh`](#sync-serversh)
- [`login-bg.sh`](#login-bgsh)
- [`vaapi-check.sh`](#vaapi-checksh)
- [`wallpaper-cycle.sh`](#wallpaper-cyclesh)
- [`rg-pre.sh`](#rg-presh)
- [`rog-ui.sh`](#rog-uish)


### `rog-update.sh`

`scripts/rog-update.sh` · 66 lines · needs root: **yes (it calls sudo itself)**

The careful way to update. It reads the **Arch Linux news** feed (`https://archlinux.org/feeds/news/`) and shows every item published since my last full system upgrade (found in `/var/log/pacman.log`), flagging titles that mention *manual intervention*, *requires*, *breaking* or *before upgrading*. Only if I agree does it run `sudo pacman -Syu`.
Afterwards it tells me which restore point was saved before the update and counts new `.pacnew` files.

`rog-update.sh --rollback` lists the restore points that the `restore` part of [rog-tune](../rog-tune/rog-tune-parts.html) saves before every pacman transaction (`/var/backups/rog-restore/*`), and reinstalls the older package versions from the pacman cache (`pacman -U`). It never touches `/etc`; the old `/etc` is in `etc.tar.gz` inside the restore point.
Spotlight offers both as actions ("System update", "Roll back the last update").

**Header comment in the script**

```text
rog-tune: update the system the careful way: show the Arch news since my last update first, then (if I agree) run pacman -Syu.
  Arch occasionally needs a manual step before an update (a changed package, a config to edit); that is announced in the news.
```

| Fact (extracted from the script) | Value |
|---|---|
| Programs it uses | `pacdiff`, `pacman` |
| Files and paths it touches | `/var/backups/rog-restore` |


### `sync-server.sh`

`scripts/sync-server.sh` · 29 lines · needs root: **no**

Manual backup of my research folders to the home server (`hp-server:Media/rog-backup/`, the external drive) over SSH with `rsync`. It runs only when I ask and **never deletes anything there** unless I turned on *Mirror deletions* (`BACKUP_MIRROR=1`, capped at 500 deletions per run).
Folders come from `~/.config/spotlight/sync.list` (written by the Settings backup dialog; default `~/notes` and `~/Documents`). Safety checks: it refuses unless the server answers over SSH, and it refuses unless `~/Media` on the server is a real mount point, otherwise a copy would silently fill the server's SSD.
Caches (`node_modules`, `__pycache__`, `.venv`, `site-packages`, `.cache`) are skipped. `-n` is a dry run. On success it records the time in `~/.local/state/spotlight/last-backup`, which Spotlight uses for the *"Your last backup was N days ago"* hint (shown after 7 days).

**Header comment in the script**

```text
rog-tune: manual backup of my research to hp-server (rsync over SSH). Runs only when I ask; never deletes anything there.
  what to copy: the folders I ticked (Settings -> Backup, or Spotlight -> "Back up"); stored one per line in ~/.config/spotlight/sync.list
  where to:     hp-server:Media/rog-backup/  = the external drive on hp-server (override with ROG_SYNC_DEST)
  sync-server.sh [-n]    -n shows what would be copied and changes nothing
```

| Fact (extracted from the script) | Value |
|---|---|
| Settings it reads (`settings.env`) | `BACKUP_MIRROR` |
| Programs it uses | `rsync`, `ssh` |
| Files and paths it touches | `~/.config/rog/settings.env`, `~/.config/spotlight/sync.list`, `~/.local/state/spotlight`, `~/.local/state/spotlight/last-backup`, `~/Documents`, `~/Media`, `~/notes` |


### `login-bg.sh`

`scripts/login-bg.sh` · 15 lines · needs root: **no**

Wallpaper hook (the wallpaper scripts call it). It does three things: it starts `accent.sh wallpaper` in the background (accent "from the wallpaper"); it builds the lock-screen image (`~/.cache/lock-bg.png`: the wallpaper scaled and cropped to 2560×1600, blurred, darkened 35 %; `i3lock` only reads PNG, once per wallpaper); and, if `/usr/share/backgrounds/rog` is writable, copies the wallpaper to `/usr/share/backgrounds/rog/current` so the greetd/ReGreet login screen (which runs as another user and cannot read `~`) shows the same picture.

**Header comment in the script**

```text
rog-tune: wallpaper hooks: keeps the login screen's wallpaper equal to the desktop wallpaper (the greeter runs as another user
and can't read ~) and builds the lock-screen image
```

| Fact (extracted from the script) | Value |
|---|---|
| Other scripts it calls | `accent.sh` |
| Programs it uses | `i3lock`, `magick` |
| Files and paths it touches | `/usr/share/backgrounds/rog/current`, `~/.cache/current_wallpaper`, `~/.cache/lock-bg.png`, `~/.cache/lock-bg.src` |


### `vaapi-check.sh`

`scripts/vaapi-check.sh` · 11 lines · needs root: **yes (it calls sudo itself)**

Read-only check for hardware video decoding: runs `vainfo` (driver `radeonsi` unless `LIBVA_DRIVER_NAME` is set) and lists H.264, HEVC, VP9 and AV1 profiles, then shows where VA-API is switched on (`chrome-flags.conf`, Firefox-family `user.js`). Needs `libva-utils`. The `vaapi` part of `rog-lean-session.sh` turns it on.

**Header comment in the script**

```text
rog-tune: is hardware video decoding available? Needs libva-utils (sudo pacman -S libva-utils). Read-only.
```

| Fact (extracted from the script) | Value |
|---|---|
| Programs it uses | `pacman`, `vainfo` |
| Files and paths it touches | `~/rog-tune/rog-lean-session.sh` |


### `wallpaper-cycle.sh`

`wallpaper-config/wallpaper-cycle.sh` · 108 lines · needs root: **no**

Next wallpaper (`Super+Y`). Picks the folder by time of day: `~/Pictures/wallpapers/day` between `WALL_DAY_START` (7) and `WALL_NIGHT_START` (19), `.../night` otherwise (or the base folder if day/night do not both exist). It keeps a per-folder file list that is rebuilt only when a hash of the file names changes, and a rotating index, then applies the image with `feh --bg-scale`, saves its path in `~/.cache/current_wallpaper` and starts `login-bg.sh` for the lock screen, login screen and accent.
The reverse script is identical except that it steps the index backwards.

**Header comment in the script**

```text
wallpaper-cycle: next wallpaper (Super+Y). The reverse script steps backwards. No root; needs feh.
  Folders: ~/Pictures/wallpapers/day and /night (or the base folder if they do not both exist). Day = WALL_DAY_START..WALL_NIGHT_START
  (settings.env, default 07:00-19:00). A per-folder list is rebuilt only when the file names change; the position is kept in
  ~/.cache/wallpaper-cycle. Writes the chosen path to ~/.cache/current_wallpaper and runs login-bg.sh (lock screen, login screen, accent).
```

| Fact (extracted from the script) | Value |
|---|---|
| Settings it reads (`settings.env`) | `NIGHT_START`, `WALL_DAY_START`, `WALL_NIGHT_START` |
| Other scripts it calls | `login-bg.sh` |
| Programs it uses | `feh` |
| Files and paths it touches | `~/.cache/current_wallpaper`, `~/.cache/wallpaper-cycle`, `~/.cache/wallpaper-cycle.`, `~/.config/rog/settings.env`, `~/Pictures/wallpapers`, `~/Pictures/wallpapers/day` |


### `rg-pre.sh`

`scripts/rg-pre.sh` · 7 lines · needs root: **no**

The `--pre` helper that lets Spotlight's deep search look inside PDFs: `ripgrep` calls it for every `*.pdf`; it extracts the text once with `pdftotext -layout` and caches it under `~/.cache/spotlight/pdf/` keyed by path and modification time, then prints the cached text. The first deep search through many PDFs is slow; later ones are fast.

**Header comment in the script**

```text
rog-tune: ripgrep --pre helper for Spotlight's deep search: PDF text is extracted once and cached (by path + mtime)
```

| Fact (extracted from the script) | Value |
|---|---|
| Programs it uses | `pdftotext` |
| Files and paths it touches | `~/.cache` |


### `rog-ui.sh`

`scripts/rog-ui.sh` · 19 lines · needs root: **no**

The client for the resident Spotlight process. `spotlight`, `apps`, `clip` write the command to `$XDG_RUNTIME_DIR/rog-ui.fifo` (the daemon is started first if it is not running); `start` / `restart` / `quit` manage the process (pid in `rog-ui.pid`); `settings` focuses the Settings window if it exists or starts `settings.py`; `backup` starts the backup chooser.
Settings is deliberately **not** resident: it starts on demand and leaves nothing in memory.

**Header comment in the script**

```text
rog-tune: client for the resident Spotlight/Settings process (it starts at login, so opening is near-instant).
  rog-ui.sh spotlight          show Spotlight (toggles); lives in a small resident process
  rog-ui.sh apps               browse every installed app (also: Alt+A inside Spotlight)
  rog-ui.sh clip               Spotlight pre-filled with "c ": my clipboard history (the same process records it)
  rog-ui.sh settings | backup  open Settings / the backup chooser as ordinary windows (nothing stays in memory afterwards)
  rog-ui.sh start | restart | quit   manage the resident Spotlight process
```

| Fact (extracted from the script) | Value |
|---|---|
| Other scripts it calls | `settings.py`, `spotlight.py` |
| Programs it uses | `i3-msg`, `setsid` |
| Files and paths it touches | `$RT/rog-ui.fifo`, `$RT/rog-ui.pid` |
