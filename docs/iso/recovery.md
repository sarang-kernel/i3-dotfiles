---
title: "Plan B: recover from GitHub"
parent: "Restore ISO"
nav_order: 5
---

# Plan B: rebuilding from the repository only

**Not tested end to end.** The ISO is the tested path; this is for the day both local ISO copies are gone. My secrets (ssh keys, Wi-Fi passwords, Bluetooth pairings, password hashes) are deliberately not in the repository, so those have to be recreated by hand.

1. Install a minimal Arch (`archinstall`, or the wiki guide) with the **`linux`** kernel, a 1 GB FAT32 boot partition at `/boot` and an ext4 root. Keep or create `/home`. Make myself user `sarang` (uid 1000) in `wheel`.
2. As root, install the packages: `pacman -S --needed - < iso/lists/native.txt` (it already leaves out zathura, btop, yazi and the LTS kernel). Then, as me: `yay -S --needed $(cat iso/lists/aur.txt)`. These come out at current versions, not the ones I had.
3. Put the system configuration back: `sudo tar -C / --keep-directory-symlink -xpf <(tar -C iso/overlay -cf - .)`. Git does not keep file modes, so check permissions afterwards. Then fix `/etc/default/grub` (new root UUID, a new `resume_offset` from `filefrag -v /swapfile`, `GRUB_DEFAULT=0`), recreate `/swapfile`, run `mkinitcpio -P`, `grub-install --removable --efi-directory=/boot` and `grub-mkconfig -o /boot/grub/grub.cfg`.
   My sudo and polkit rules are not in the overlay on purpose: add `sarang ALL=(ALL) ALL` in `/etc/sudoers.d/` myself.
4. Configs: clone the dotfiles repo and run its `install.sh`, then clone my `nvim` repo.

The published `iso/overlay/` holds 72 files (mkinitcpio, modprobe, sysctl, udev, tmpfiles, systemd, texmf, lightdm, iwd defaults, a few `/usr/local` scripts, the wallpaper, …); see the [file index](../reference/file-index.html).
