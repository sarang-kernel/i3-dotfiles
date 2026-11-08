# rog-iso

My "everything is on fire, press this" button for the ASUS ROG Flow X13.

It's a bootable Arch ISO that rebuilds my laptop from scratch, **completely offline**: the packages, `/etc`, the services, my configs, my dev tools. Stable `linux` kernel only (no LTS, I got tired of choosing in GRUB). My own files (Documents, Development, Media, browser profiles...) are not in it, and the default mode never touches them.

## How I use it
1. Write it to a USB stick (16 GB or more): `sudo dd if=rog-restore-*.iso of=/dev/sdX bs=4M status=progress oflag=sync`
2. Boot it (UEFI), run `rog-restore`, and pick **1) Rebuild, keep /home**. It formats only the boot and root partitions. `/home` stays exactly as it was, and my snapshot configs land in `~/.rog-snapshot` instead of overwriting anything.
   Option 2 wipes a whole disk (new SSD, total disaster) and puts the configs straight into the fresh `/home`.
3. Reboot. The login screen, hibernation (swap file and resume offset are recalculated), the NVIDIA module and all the `rog-tune` tweaks come back on their own.

## What's inside
| part | content |
|---|---|
| `/opt/rog/repo` | every package at the version I had installed (941 from the Arch repos, 10 from the AUR) |
| `overlay.tar.zst` | my `/etc` changes, which services are enabled, `/usr/local`, the wallpaper, rog state (no secrets) |
| `home-config.tar.zst` | `~/.config`, shell and X dotfiles, `~/.local`, Rust, nvm, Neovim data, rog-tune, my dotfiles clones |
| `secrets.tar.zst` | ssh and gnupg keys, SSH host keys, Wi-Fi passwords, Bluetooth pairings, password hashes. **Only in my local ISOs, never published** |

The AUR packages are repacked from the files that are actually installed, because rebuilding them later is a gamble (old Chrome versions simply vanish from Google's servers).

Left out on purpose: zathura, btop, yazi (and `linux-lts`), browser and Electron profiles (Chrome, Zen, Discord, Ferdium, Teams), caches, `~/.cargo/registry`, the pnpm store. Those belong to my file backup.

## Rebuilding it
```
./prepare.sh          # as me: downloads the repository (~7 GB), repacks the AUR packages, bundles my home config
sudo ./build.sh       # collects the root-only state and builds the ISO into out/ (needs ~45 GB free)
./test-qemu.sh fresh && ./test-qemu.sh rebuild   # boots it in a VM and runs the whole restore (needs /dev/kvm)
```
Both VM scenarios run the real restore script end to end and then boot the result: a blank disk, and a rebuild that has to keep a test file in `/home`.

## Honest notes
- I've tested this in a virtual machine (fresh disk, and rebuild-keeping-/home). I haven't yet torn down the real laptop with it, and I'd rather not find out the hard way, so please treat the first real use with a little suspicion.
- After a restore, run `sudo pacman -Syu` once the Wi-Fi is up: the new system has no package databases until it can reach a mirror.
- The ISO is about 9 GB, so write it with `dd` (or exFAT), not onto a FAT32 stick.

## This GitHub copy
GitHub won't take a 9 GB file (100 MB per file, tops), so this folder is the **recipe**: scripts, package lists, the scrubbed `/etc` overlay (`overlay/`) and the live-image profile. No keys, no passwords, no Wi-Fi secrets, and no sudo or polkit rules either. If both my local ISO copies are gone, `recover-from-github.md` is plan B.
