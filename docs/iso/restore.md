---
title: "rog-restore"
parent: "Restore ISO"
nav_order: 3
---

# `rog-restore`

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


The installer on the ISO. Run as root (the live ISO logs in as root).

```text
rog-restore                       interactive (asks before anything is erased)
--mode rebuild|fresh|devices      rebuild = format boot+root, KEEP /home (default when the old partitions are found)
                                  fresh   = erase a whole disk (--disk /dev/nvme0n1), new layout, empty /home
                                  devices = I name the partitions (--esp --root [--home])
--home-mode restore|stage|skip    how to treat my configs/dev tools from the snapshot
--yes                             no questions (used by the automatic test)
--test                            test run in a virtual machine
```

## Modes

| Mode | What it formats | `/home` |
|---|---|---|
| **rebuild** (1) | Only the boot (FAT32) and root (ext4) partitions, found by the UUIDs in `snapshot.info` | Kept exactly as it is |
| **fresh** (2) | A whole disk: 1 GB ESP, `ROOT_GB` GB root, the rest as `/home`. Refuses the ISO's own medium. You must type the disk name | New and empty |
| **devices** | The partitions you name | The one you name, or none |

Before formatting it asks you to type `ERASE` (rebuild) or the disk name (fresh).

## `--home-mode`

- `restore` (default on an empty or fresh `/home`): configs and dev tools are unpacked straight into `/home/<user>`, and the ssh/gnupg secrets with them.
- `stage` (default when `/home` already has files): everything goes to `~/.rog-snapshot`, **nothing is overwritten**; I copy what I want.
- `skip`: no home snapshot.

## What it does, in order

1. **Pick the target** (above). Old UUIDs are **reused** (`mkfs.ext4 -U`, `mkfs.fat -i`) when no other device carries them, so the next restore still recognises the machine.
2. **Partition / format** and mount (`noatime,lazytime`).
3. **Swap file**: `mkswap --file` of `SWAP_GB` (18 GB by default), because hibernation needs it.
4. **Packages**: `pacstrap -C offline.conf -K -M` of `native.txt` plus `aur.txt` from the ISO (a few minutes; DKMS builds the NVIDIA module at the end). Then `pacman -D --asdeps` and `--asexplicit` restore my install reasons from `explicit-all.txt`, so only what I installed myself is "explicit". The package cache is emptied afterwards (the packages stay on the ISO).
5. **System state**: extracts `overlay.tar.zst` (`--keep-directory-symlink`), writes `fstab` with `genfstab -U` (adds the swap line), sets the time zone.
6. **Hibernation**: reads the swap file's physical offset with `filefrag` and rewrites `resume=UUID=…` and `resume_offset=…` in `/etc/default/grub` (and `RESUME_OFFSET` in the initcpio config if present); `GRUB_DEFAULT=0`.
7. **User and passwords**: creates my group and user with the same uid, adds `wheel`, puts the `greeter` user in `video`, generates locales, sets the clock, and installs the **password hashes** from the secrets (or asks for a new password if none).
8. **Secrets**: SSH host keys, Wi-Fi (iwd) and Bluetooth state go back to `/etc/ssh`, `/var/lib/iwd`, `/var/lib/bluetooth`.
9. **Boot**: `mkinitcpio -P`, `grub-install --target=x86_64-efi --bootloader-id=Arch --removable`, `grub-mkconfig`. Writes `/etc/rog-restore-info` with the date and snapshot.
10. **Checks** (printed `ok` / `FAIL`): stable kernel and no LTS; amdgpu in the boot image; the resume hook; a GRUB entry for linux with the right resume offset; the bootloader on the ESP; empty package cache; no LTS packages; greetd enabled; fstab has root, boot and swap; sudo rule for me; install reasons restored (fewer than 400 explicit packages).
11. Kills the `gpg-agent` that `pacman-key` leaves behind and unmounts (lazily if something still holds on), then offers to reboot.

## After the first boot

Run `sudo pacman -Syu` once Wi-Fi works (the new system has no package databases until it can reach a mirror).
