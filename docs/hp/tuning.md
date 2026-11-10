---
title: "Boot and server tuning"
parent: "HP desktop and server"
nav_order: 8
---

# Boot and server tuning

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


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
