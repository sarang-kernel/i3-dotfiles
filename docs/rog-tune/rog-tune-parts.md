---
title: "rog-tune.sh parts"
parent: "rog-tune"
nav_order: 1
---

# `rog-tune.sh`: the root-side parts

`rog-tune.sh` holds every **root-side** change I made to the ROG Flow X13: power saving, boot options, the login screen, hibernation, package-manager hooks, services. It is organised as *parts*: each part is a self-contained, named change.

```text
Root-side tuning for the ROG Flow X13. Dry run by default; backs up before changing; --undo restores.
  sudo ~/rog-tune/rog-tune.sh [parts…]            show every change as a diff
  sudo ~/rog-tune/rog-tune.sh --apply [parts…]    do it
  sudo ~/rog-tune/rog-tune.sh --undo              restore the most recent backup

```

Three rules make it safe to run on the machine I live on:

1. **Dry run by default.** Without `--apply` it prints every change as a diff and touches nothing.
2. **Backups.** `--apply` copies every file it is about to change into `/var/backups/rog-tune/<timestamp>/files` and records a `manifest` and the list of `parts`.
3. **`--undo`** restores the most recent backup: files go back (or are removed if they did not exist before) and the part-specific side effects are reversed (units re-enabled, sysctl reloaded, the NVIDIA runtime power setting turned back on, GRUB config regenerated and so on).

With no parts given it runs `gpu sysctl journal`. Every other part is **opt-in**; the table says which ones I actually applied is *not* tracked here, because `--undo` and the dry run are the source of truth on the machine. Set `ROG_ROOT` (a test root) and `ROG_SYSFS` to try a part against a scratch directory: in that mode `live` only prints what it would run.

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


## The 30 parts

Descriptions are the header of the script, verbatim. *Writes* lists the files the script creates or edits for that part (extracted from the code).


### `gpu`

let the RTX 4050 power itself off when idle. The driver already allows it (NVreg_DynamicPowerManagement=0x02) but the kernel is told to keep the card on, so it has never suspended (~5 W constant, and heat)


**Writes:** `/etc/udev/rules.d/80-nvidia-pm.rules`


### `sysctl`

NMI watchdog off (saves a little power), no swap read-ahead (swap is zram)


**Writes:** `/etc/modules-load.d/rog-bbr.conf`, `/etc/sysctl.d/90-rog.conf`, `/etc/sysctl.d/91-rog-net.conf`


### `journal`

cap the system log at 300 MB, sync it every 5 min


**Writes:** `/etc/systemd/journald.conf.d/50-rog.conf`


### `charge80`

stop charging at 80 % (battery health: this machine lives on the charger). Opt-in


### `xgpu`

Xorg stops attaching the NVIDIA GPU as a screen, which lets it sleep even under X. Opt-in, because OpenGL "prime-run" offload needs that screen (Vulkan games and CUDA are unaffected)


**Writes:** `/etc/X11/xorg.conf.d/10-no-nvidia-screen.conf`


### `lts`

make linux-lts the default kernel in GRUB (menu entry 0 is the 7.x kernel today). Opt-in


**Writes:** `/boot/grub/grub.cfg`, `/etc/default/grub`


### `svc`

disable valkey (nothing depends on it) and avahi (mDNS; nothing needs it here). Opt-in


### `aspm`

PCIe power saving to its deepest level (powersupersave), applied at every boot. Opt-in


**Writes:** `/etc/tmpfiles.d/rog-aspm.conf`


### `misc`

transparent hugepages → madvise (fewer latency spikes), 10 s service stop timeout (faster shutdown), no core dumps (a crashing browser stops burning CPU/disk), unused watchdog/pc-speaker modules blacklisted. Opt-in


### `fstab`

mount / and /home with noatime (stops a disk write on every file read). Opt-in


**Writes:** `/etc/fstab`


### `initramfs`

rebuild the boot image without the kms hook: it is 158 MB today (108 MB is NVIDIA GSP firmware that is never used at boot), which GRUB reads from the FAT partition on every boot. ~46 MB afterwards. Opt-in


**Writes:** `/etc/mkinitcpio.conf`


### `cmdline`

add nowatchdog to the kernel command line (needs grub-mkconfig). Opt-in


**Writes:** `/boot/grub/grub.cfg`, `/etc/default/grub`


### `mainline`

make the regular `linux` kernel (7.x) the GRUB default instead of linux-lts, because LTS shows a black screen on this laptop. LTS stays in the menu as the fallback. Don't combine with `lts`. Opt-in


**Writes:** `/boot/grub/grub.cfg`, `/etc/default/grub`


### `psr`

amdgpu.dcdebugmask=0x410 on the kernel command line: turns off Panel Self Refresh and Panel Replay for the laptop panel. The LTS kernel enables PSR on this panel and the screen goes black on static content (login screen) and blacks out now and then; the 7.x kernel leaves it off and works. Costs a little battery at idle (the panel refreshes itself less cleverly). Opt-in


**Writes:** `/boot/grub/grub.cfg`, `/etc/default/grub`


### `dm`

boot to a graphical login screen (LightDM, warm and dark) instead of a text console: sets the default target to graphical.target (LightDM was enabled but the machine boots to multi-user, so it never started). Opt-in


**Writes:** `/etc/gtk-3.0/settings.ini`, `/etc/lightdm/lightdm-gtk-greeter.conf`, `/etc/lightdm/lightdm.conf.d/50-rog.conf`, `/etc/polkit-1/rules.d/50-rog-sensor.rules`, `/usr/local/lib/rog/greeter-rotate.sh`, `/usr/share/backgrounds/rog`, `/usr/share/backgrounds/rog/current`


### `grubfast`

GRUB menu hidden and timeout 0: saves 1 s per boot. I can no longer pick the 7.x kernel at boot without a live USB. Opt-in


**Writes:** `/boot/grub/grub.cfg`, `/etc/default/grub`


### `oom`

earlyoom: when RAM is nearly gone, kill the biggest browser tab/process instead of letting the machine freeze. Needs the earlyoom package. Opt-in


**Writes:** `/etc/default/earlyoom`


### `hibernate`

make hibernation work. /swapfile (18 GB) and resume=UUID exist, but the boot image has no resume hook and the kernel lacks resume_offset (mandatory for a swap FILE), so a hibernate today would never come back. Adds both, plus the NVIDIA sleep services (video memory is saved to /var/tmp). Opt-in. After the reboot test it ONCE by hand: save my work, then `systemctl hibernate`


**Writes:** `/boot/grub/grub.cfg`, `/etc/default/grub`, `/etc/mkinitcpio.conf`, `/etc/modprobe.d/rog-nvidia-sleep.conf`


### `sth`

lid closed on battery = suspend, then hibernate after 90 min (no overnight drain). On AC it only suspends. Opt-in; it refuses to run until hibernate is active in the running kernel


**Writes:** `/etc/systemd/logind.conf.d/50-rog-lid.conf`, `/etc/systemd/sleep.conf.d/50-rog.conf`


### `slimboot`

RETIRED, refuses to run (it made the login screen race the driver). Was: boot image without the amdgpu driver and its firmware: 46 MB -> 13 MB (33 MB of it is firmware for AMD GPUs this laptop does not have). amdgpu then loads from the root disk a moment later. A smaller image is not extra work, but the real boot-time gain is UNMEASURED here: try it as an A/B test (note `systemd-analyze`, apply, reboot, compare; --undo restores the old images). Opt-in


**Writes:** `/etc/mkinitcpio.conf`


### `pm`

hardware power saving ON BATTERY: PCI devices (Wi-Fi, NVMe, bridges ...) may power down when idle; on AC each device returns to its own original setting. A udev rule re-applies it at every plug/unplug. The NVIDIA GPU (own rule) and the AMD sensor hub (autorotate) are left alone. Opt-in


**Writes:** `/etc/udev/rules.d/81-rog-pm.rules`, `/usr/local/lib/rog/pm-apply.sh`


### `net`

stop systemd-resolved listening for LLMNR and mDNS (UDP 5355/5353 on every interface): nothing here uses them. DNS itself is unchanged. Opt-in


**Writes:** `/etc/systemd/resolved.conf.d/90-rog.conf`


### `restore`

before every pacman install/upgrade/removal, save a restore point (package lists + /etc + GRUB config, ~2 MB, last 5 kept) in /var/backups/rog-restore so a bad update can be put right by hand. A hook that never blocks pacman. Opt-in


**Writes:** `/etc/pacman.d/hooks/00-rog-restore.hook`, `/usr/local/lib/rog/restore-point.sh`


### `greetd`

replace LightDM with greetd + ReGreet (GTK4 login screen showing my wallpaper). Needs: sudo pacman -S greetd greetd-regreet sway (sway, not cage, so the login screen can follow the accelerometer: it rotates live, touch included) The greeter runs on VT7; my tty1/tty2 text login stays as a safety net (undo re-enables LightDM). Opt-in


**Writes:** `/etc/greetd/config.toml`, `/etc/greetd/regreet.css`, `/etc/greetd/regreet.toml`, `/usr/local/lib/rog/greeter-start.sh`, `/usr/share/backgrounds/rog`, `/usr/share/backgrounds/rog/current`


### `health`

weekly SSD health report (wear, spare, temperature, errors) shown in Settings -> System. Needs smartmontools. Opt-in


**Writes:** `/etc/systemd/system/rog-health.service`, `/etc/systemd/system/rog-health.timer`, `/usr/local/lib/rog/health.sh`


### `nice`

ananicy-cpp with a few rules: compilers/rsync run at low priority, the desktop (Xorg, i3, picom) at higher. Needs ananicy-cpp (check idle CPU afterwards; undo disables it). Opt-in


**Writes:** `/etc/ananicy.d/00-rog/rog.rules`


### `mirrors`

refresh the pacman mirror list weekly with reflector (fastest 20 https mirrors from the last 12 h; no country guessed). Needs reflector. Opt-in


**Writes:** `/etc/xdg/reflector/reflector.conf`


### `pkgcache`

keep the 2 newest versions of each package in /var/cache/pacman/pkg (8 GB there now). Opt-in


### `speed`

small speed wins: lazytime on / and /home (inode timestamps are flushed in batches, fewer SSD writes), TCP fast open + no slow-start after idle + MTU probing (snappier page loads on Wi-Fi), no split-lock penalty, no background memory compaction, makepkg builds on all cores, pacman downloads 10 packages at once. Opt-in


**Writes:** `/etc/fstab`, `/etc/makepkg.conf.d/rog-speed.conf`, `/etc/pacman.conf`, `/etc/sysctl.d/92-rog-speed.conf`


### `tidy`

housekeeping: removes the invalid `Enable=` line from /etc/bluetooth/main.conf (bluetoothd warns about it on every start) and stops the desktop-portal GTK backend from being started for the login-screen user (it fails there on every boot). Opt-in


**Writes:** `/etc/bluetooth/main.conf`, `/etc/systemd/user/xdg-desktop-portal-gtk.service.d/rog-greeter.conf`


## Running it

```bash
sudo ~/rog-tune/rog-tune.sh                       # dry run of the default parts
sudo ~/rog-tune/rog-tune.sh --apply greetd hibernate   # apply some parts
sudo ~/rog-tune/rog-tune.sh --undo                # put the last backup back
```


## Parts that are retired

`slimboot` refuses to run: it removed the `amdgpu` driver from the boot image, which let the greetd login screen race the GPU driver at boot. `amdgpu` is back in the boot image (`MODULES=(amdgpu)` in `mkinitcpio.conf`) and the greeter start script waits for the driver. See [Changes](../changes/).
