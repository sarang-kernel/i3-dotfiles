---
title: "What is inside"
parent: "Restore ISO"
nav_order: 1
---

# What is inside

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


| Part | In the image | Content |
|---|---|---|
| Package repository | `/opt/rog/repo` | Every package at the version I had installed: **941 from the Arch repos and 10 from the AUR** (counts at the last build; `iso/lists/native.txt` and `aur.txt` are the current lists) |
| `overlay.tar.zst` | `/opt/rog/` | My `/etc` changes (every packaged file marked *modified* and every file nobody owns), which services are enabled, `/usr/local`, the wallpaper in `/usr/share/backgrounds/rog`, `/var/lib/rog`. No secrets |
| `home-config.tar.zst` | `/opt/rog/` | `~/.config`, shell and X dotfiles, `~/.local`, Rust, nvm, Neovim data, `rog-tune`, my dotfiles clones |
| `secrets.tar.zst` | `/opt/rog/` | ssh and gnupg keys, SSH host keys, Wi-Fi passwords, Bluetooth pairings, password hashes. **Only in local ISOs, never published** |
| `snapshot.info` | `/opt/rog/` | Machine facts: snapshot date, root/boot/home UUIDs, user name and uid, time zone, swap and root sizes |
| `offline.conf` | `/opt/rog/` | A pacman config pointing at the local repo with signature checking off (the packages were already verified when downloaded) |

AUR packages are **repacked from the files that are actually installed** (`iso/tools/repack-installed.py` rebuilds a `.pkg.tar.zst` from `/var/lib/pacman/local` metadata), because rebuilding them later is a gamble (old Chrome versions vanish from Google's servers).

## Left out on purpose

zathura, btop, yazi (and `linux-lts`), each with the packages only they needed (`lists/removed.txt` is the exact list); browser and Electron profiles (Chrome, Zen, Discord, Ferdium, Teams), caches, `~/.cargo/registry` and the pnpm store. Those belong to my file backup.

## The lists (`iso/lists`)

| File | Content |
|---|---|
| `native.txt`, `aur.txt` | What gets installed |
| `explicit-all.txt`, `explicit-native.txt` | Which packages I installed on purpose (the rest are marked *as dependencies* again after the restore, so `pacman -Qe` stays short) |
| `native-all.txt` | All native packages including the removed ones |
| `removed.txt` | The left-out set |
