---
title: "Script conventions"
parent: "Scripts"
nav_order: 6
---

# Script conventions

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


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
