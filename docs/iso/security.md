---
title: "Security"
parent: "Restore ISO"
nav_order: 6
---

# Security

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


## What is where

| Copy | Contains secrets? |
|---|---|
| **Local ISO** (on the laptop and on the home server) | **Yes, unencrypted:** ssh and gnupg keys, SSH host keys, Wi-Fi passwords, Bluetooth pairings, password hashes. Treat the ISO file like a private key. It is mode 600 |
| **GitHub recipe** (`iso/` in the dotfiles repo) | No. `publish.sh` strips sudoers, polkit, ssh, NetworkManager files and lock files, then runs `scan-secrets.sh` (it fails the publish if a key, token, password or similar string is found) |

Passphrase-encrypting the local ISOs is possible but not done; ask for it if you want it.

## The publish checks

- `build.sh` refuses to build if a secret-looking path is in the public overlay list.
- `publish.sh` copies the recipe (scripts, lists, `profile-overlay`, `tools`, the README files) into the dotfiles clone, unpacks the overlay (deleting any file over 1 MB, which is the wallpaper copy), then **removes** `etc/sudoers` and `sudoers.d`, `etc/polkit-1`, `etc/ssh`, `etc/NetworkManager`, `git-filter-repo` (a third-party tool), `.pwd.lock` and `health.txt`, and runs `scan-secrets.sh` on the result. It does not commit; I review and commit by hand.
- `scan-secrets.sh DIR` fails if any file contains a private-key header, a code-hosting, cloud or chat token, a Wi-Fi passphrase or pre-shared-key line, a password assignment or a password hash, or if any file *name* looks like a key or credential store (private keys, certificates, `known_hosts`, SSH host keys, `shadow*`, GitHub CLI hosts files, password-manager databases, anything under `.ssh`, `.gnupg`, the iwd or Bluetooth state folders, NetworkManager connections, or shell history).
- Commits to the public repo carry no attribution lines (my own rule for my repositories).

## After a restore

Passwords and keys return from the secrets bundle, so the first boot is already "me". If the ISO was ever copied somewhere untrusted, rotate the SSH keys and Wi-Fi passwords.
