---
title: "Login screen and installed helpers"
parent: "rog-tune"
nav_order: 3
---

# Login screen and installed helpers

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


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
