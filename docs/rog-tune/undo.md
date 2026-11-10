---
title: "Backups and undo"
parent: "rog-tune"
nav_order: 5
---

# Backups and undo

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


## Root side (`rog-tune.sh`)

`--apply` creates `/var/backups/rog-tune/<timestamp>/` containing `files/<absolute path>` (a copy of every file it is about to overwrite), `manifest` (every path it touched), `parts` (which parts ran) and some part-specific lists (`svc`, `hib`). `--undo` restores the **most recent** backup:

1. For each path in the manifest: copy the backed-up file back, or delete the path if it did not exist before.
2. For each part in `parts`, reverse what files cannot: NVIDIA runtime power back to `on`, `sysctl --system`, journald restart, `asusctl battery limit 100`, re-enable stopped services, disable services it enabled (`rog-health.timer`, `ananicy-cpp`, `reflector.timer`, `earlyoom`, hibernate's NVIDIA sleep services), restore PCI power-control values saved in `/run/rog-pm.orig`, reload udev, restart resolved, remount without `lazytime`/`noatime`, `systemctl set-default multi-user.target` (for `dm`), re-enable LightDM and disable greetd (for `greetd`), regenerate GRUB.

Because `--undo` takes the newest backup only, undo after each experiment rather than at the end of a long session.

## User side (`rog-lean-session.sh`)

Before changing a file it saves it to `~/.local/share/rog-tune/` as `i3config.before`, `polybar.ini.before`, `kitty.conf.before`, `bashrc.before`, `picom.conf.before`, `rofi-main.before`, `rofi-power.before`, `wallcycle.before`, `wallcycle-rev.before`, `lock.before`. `--undo` copies them back and removes `created.list` files, autostart stubs with the `rog-tune` marker, the Firefox/Zen `user.js` blocks between `rog-tune` markers, and re-enables things it had disabled (psd, dunst, the automount).

## Pacman restore points

The `restore` part installs a pacman hook (`/etc/pacman.d/hooks/00-rog-restore.hook`) that saves a **restore point before every install, upgrade or removal**: package lists with versions (`versions.txt`), the running kernel (`kernel.txt`), `/etc` (`etc.tar.gz`) and the GRUB config, about 2 MB each, last five kept, in `/var/backups/rog-restore/`. It never blocks pacman. `rog-update.sh --rollback` uses them (see [System tools](../scripts/system.html#rog-updatesh)).

## Backups I keep by hand

After every round of changes I copy the files I am about to change to `~/.local/share/rog-backups/` with a suffix like `.bak30`. These are not used by any script; they are insurance and safe to delete when everything has run for a while.
