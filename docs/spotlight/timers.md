---
title: "Timers and reminders"
parent: "Spotlight"
nav_order: 5
---

# Timers and reminders

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


## Typing them

| You type | Meaning |
|---|---|
| `timer 25m` | Ring in 25 minutes |
| `timer 1h30m`, `timer 1 hour 15 min`, `timer 90s` | Hours, minutes, seconds, in any combination; units `h hr hrs hour hours`, `m min mins minute minutes`, `s sec secs second seconds` |
| `timer 10` | A bare number is **minutes** |
| `timer 25m tea` | The text after the time is the label |
| `remind in 10m call back` | Reminder after 10 minutes |
| `remind 15:30 stand up` | Reminder at 15:30 today (tomorrow if that time has passed) |
| `remind 3pm tea`, `remind 3:30 pm …` | 12-hour times; `am`/`pm` handled |
| `remind tomorrow 9am email` | `tomorrow` (or `tmrw`) shifts the day |
| `remind me to …` | The words *me* and *to* are optional |
| `timers`, `alarms`, `reminders`, `timer`, `remind` | List what is pending; **Enter on a row cancels it** |

Limits: a timer must be longer than zero and at most 7 days. A lone number in a `remind` is not a time of day, so `remind 5 x` is not accepted.

The result row says when it will ring (*Rings at 13:12 · press Enter to start*). Nothing is scheduled until you press Enter.

## How an alarm works

1. Spotlight starts a **transient systemd user timer** with `systemd-run --user --collect --unit=rog-alarm-<timestamp> --on-active=<ms> --timer-property=AccuracySec=10ms`, passing `DISPLAY`, `XAUTHORITY`, `XDG_RUNTIME_DIR` and the D-Bus address with `--setenv`. It fires about 0.4 s early, which is how long the alarm window needs to start.
2. The unit runs `alarm.py "label"`.
3. Spotlight also records the alarm in `~/.local/state/spotlight/alarms.json` (unit name, message, due time) so it can list it; entries more than a minute past due are pruned on the next write.
4. Because it is a systemd unit, **the alarm survives closing Spotlight and even logging out of Spotlight's process**; it does not survive a reboot (the timer is transient).

## The alarm window

A centred card (class `RogAlarm`, i3 rule `border pixel 3, move position center`) showing the message with an alarm-clock glyph. It stays **until dismissed**: `Enter` or `Esc`. `S` **snoozes five minutes** (it schedules another transient timer and records it). A sound plays up to four times (`/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga` through `paplay`, 1.5 s apart) unless `ALARM_SOUND=0` (Settings → General → *Play a sound when one rings*).
