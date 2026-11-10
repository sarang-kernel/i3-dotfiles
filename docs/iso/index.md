---
title: "Restore ISO"
nav_order: 6
has_children: true
description: "A bootable Arch ISO that rebuilds the laptop offline"
---

# Restore ISO

My "everything is on fire, press this" button. A bootable Arch ISO that **rebuilds the ROG Flow X13 completely offline**: the packages (at the versions I had), `/etc`, the services, my configs, my dev tools. The stable `linux` kernel only (no LTS). My own files (Documents, Development, Media, browser profiles …) are not in it, and the default mode never touches them.

The recipe is in the repo under `iso/`; the ISO itself (about 9.5 GB) is too big for GitHub.

## How I use it

1. Write it to a USB stick of 16 GB or more: `sudo dd if=rog-restore-*.iso of=/dev/sdX bs=4M status=progress oflag=sync`
2. Boot it (UEFI), run `rog-restore`, pick **1) Rebuild, keep /home**. It formats only the boot and root partitions; `/home` stays exactly as it was.
3. Reboot. Login screen, hibernation (swap file and resume offset are recalculated), the NVIDIA module and the tuning come back by themselves. After a restore run `sudo pacman -Syu` once Wi-Fi is up.

## Pages

| Page | What you get |
|---|---|
| [What is inside](contents.html) | The four parts of the image and what is deliberately left out |
| [Building it](build.html) | `prepare.sh`, `build.sh`, disk space, the AUR repack |
| [rog-restore](restore.html) | Every mode and option of the installer, step by step |
| [Testing](testing.html) | The QEMU test harness and the self-test |
| [Plan B: recover from GitHub](recovery.html) | When both local ISOs are gone |
| [Security](security.html) | What is in the local ISO and what is published |
