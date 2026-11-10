---
title: "The helper tools"
parent: "rog-tune"
nav_order: 4
---

# The helper tools

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


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
