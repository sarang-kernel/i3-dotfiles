---
title: "settings.env reference"
parent: "Scripts"
nav_order: 7
---

# `settings.env` reference

`~/.config/rog/settings.env` is one plain file of `KEY="value"` lines. The Settings app writes it (sorted, with a comment header), and every script and helper program **sources or greps it**: there is no daemon holding state. You can edit it by hand; the Settings app re-reads the file before every write (`setv`), so a change made by `power-mode.sh` meanwhile is not lost.

`NIGHT_GAMMA` is derived: the app converts `NIGHT_K` (colour temperature) into `R:G:B` gamma factors so the shell scripts need no maths. Older versions stored `AC_PROFILE` / `BAT_PROFILE` and `SETTINGS_DARK`; on load they are migrated to `MODE_AC` / `MODE_BAT` and `APPEARANCE`, and the old keys are dropped on the next save.

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


## All 39 settings

Generated from the `DEFAULTS` table in `settings.py` and from which scripts mention each key.


| Key | Default | Where I change it in Settings | Read by |
|---|---|---|---|
| `ACCENT_HEX` | `#c47f1c` | General | `accent.sh`, `alarm.py`, `i3lock/lock.sh`, `power-menu.py`, `spotlight.py` |
| `ACCENT_MODE` | `amber` | General | `accent.sh`, `alarm.py`, `power-menu.py`, `spotlight.py` |
| `ADAPTIVE` | `1` | Display | `display-agent.py` |
| `ADAPTIVE_IDLE_S` | `60` | Display | `display-agent.py` |
| `ALARM_SOUND` | `1` | General | `alarm.py` |
| `APPEARANCE` | `light` | General | `alarm.py`, `power-menu.py`, `spotlight.py` |
| `AUTOCAFFEINE` | `1` | Power & Performance | `autocaffeine.sh` |
| `AUTOQUIET` | `1` | Power & Performance | `power-watch.sh` |
| `AUTOQUIET_PCT` | `20` | Power & Performance | `power-watch.sh` |
| `BACKUP_MIRROR` | `0` | Backup | `sync-server.sh` |
| `CINEMA` | `1` | Display | `display-agent.py` |
| `CINEMA_HZ` | `71.928` | Display | `power-watch.sh` |
| `FAN_CURVE` | `default` | Power & Performance |  |
| `IDLE_HZ` | `60` | Display | `display-agent.py`, `power-watch.sh` |
| `KEY_DELAY` | `250` | Keyboard & Mouse | `input-apply.sh` |
| `KEY_RATE` | `50` | Keyboard & Mouse | `input-apply.sh` |
| `LOCK_AC` | `10` | Power & Performance | `power-watch.sh` |
| `LOCK_BAT` | `2` | Power & Performance | `power-watch.sh` |
| `MIC_MUTE_LOGIN` | `0` | General | `login-apply.sh` |
| `MODE_AC` | `balanced` | Power & Performance | `power-mode.sh`, `power-watch.sh` |
| `MODE_BAT` | `quiet` | Power & Performance | `power-mode.sh`, `power-watch.sh` |
| `NIGHT_END` | `7` | Display | `alarm.py`, `nightlight.sh`, `power-menu.py`, `spotlight.py` |
| `NIGHT_K` | `4000` | Display |  |
| `NIGHT_START` | `19` | Display | `alarm.py`, `nightlight.sh`, `power-menu.py`, `spotlight.py` |
| `OFF_AC` | `15` | Power & Performance | `power-watch.sh` |
| `OFF_BAT` | `3` | Power & Performance | `power-watch.sh` |
| `PTR_SPEED` | `0` | Keyboard & Mouse | `input-apply.sh` |
| `RATE_AC` | `90` | Display | `power-watch.sh` |
| `RATE_BAT` | `60` | Display | `power-watch.sh` |
| `SHOT_SAVE` | `1` | General | `shot.sh` |
| `SPOT_OPACITY` | `62` | Spotlight | `spotlight.py` |
| `SPOT_RECENTS` | `1` | Spotlight | `spotlight.py` |
| `TP_DWT` | `1` | Keyboard & Mouse | `input-apply.sh` |
| `TP_NATURAL` | `0` | Keyboard & Mouse | `input-apply.sh` |
| `TP_TAP` | `1` | Keyboard & Mouse | `input-apply.sh` |
| `WALL_DAY_START` | `7` | Wallpaper | `wallpaper-config/wallpaper-cycle.sh` |
| `WALL_EVERY` | `0` | Wallpaper | `wallpaper-timer.sh` |
| `WALL_NIGHT_START` | `19` | Wallpaper | `wallpaper-config/wallpaper-cycle.sh` |
| `WS_ICONS` | `0` | Top Bar | `display-agent.py` |


## Where the defaults come from

The table above shows what a fresh install gets. My own `rog/settings.env` in the repo differs slightly (for example a night tint of 2913 K from 20:00 to 06:00 and the dark theme). Settings → General → *Export settings* saves this file together with Spotlight's `aliases`, `roots` and `sync.list` as one tarball, and *Import settings* restores them and re-applies power, night tint and input.
