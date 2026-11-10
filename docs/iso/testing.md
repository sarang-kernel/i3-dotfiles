---
title: "Testing"
parent: "Restore ISO"
nav_order: 4
---

# Testing

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


I do not trust a backup I have not restored. `test-qemu.sh` boots the real ISO in a virtual machine and runs the real `rog-restore`.

```bash
./test-qemu.sh fresh      # blank disk -> fresh install -> first-boot self-test (also creates a sentinel file in /home)
./test-qemu.sh rebuild    # same disk -> rebuild keeping /home -> self-test (the sentinel must survive)
PATCH=0 ./test-qemu.sh fresh   # use exactly what is baked into the ISO (the final check of a build)
```

Needs `qemu-base`, `edk2-ovmf` and `/dev/kvm`. The VM gets 4 GB RAM and 6 CPUs at low priority (`nice`, `ionice`); logs are `work/vm/<stage>-install.log` and `<stage>-boot.log`.

## How the VM test works

- It extracts the ISO's kernel and initramfs and boots them directly with `-kernel/-initrd`, with `rog_test=<stage>` on the command line and the serial console on `ttyS0`.
- `rog-test-live.service` (in the ISO, `ConditionKernelCommandLine=rog_test`, so it **never runs on real hardware**) calls `rog-test-live`, which reads the scenario from `/proc/cmdline` and runs `rog-restore --test --yes --mode fresh --disk /dev/vda --home-mode restore` (scenario `fresh`) or `rog-restore --test --yes --mode rebuild --home-mode stage` (scenario `rebuild`), then powers off. `--test` uses a 1 GB swap file and a 40 GB root, gives the user the password `rogtest`, installs `selftest.sh` as a service on the new system and puts the serial console on the kernel command line.
- **`PATCH=1`** (the default) boots a small extra disk with the newest `rog-restore`, `offline.conf` and `selftest.sh`, so fixes can be tested without rebuilding the 9.5 GB ISO. `PATCH=0` tests the baked-in versions.

## The self-test (`selftest.sh`)

Runs once on the first boot of a test restore, prints to the serial log and powers off: kernel version, `/boot` files, system state and **failed units**, enabled units, package counts (total, explicit, foreign, LTS), `pacman -Qkq` problems, cache size, root usage, users and the greeter's groups, swap, command line, amdgpu in the boot image, the **sentinel** (created, or *survived*), the contents of `/home`, the staged snapshot, a check of six key files (`i3/config`, `.bashrc`, `.rustup`, `.nvm`, the ssh key, gnupg), `/etc` facts, SSH host key presence, iwd and Bluetooth state, sudo rules, greetd and the display-manager link, DKMS status.

## What the tests found (and fixed)

Five real bugs: the install reasons of packages, an unmount that failed because a `gpg-agent` stayed alive, two wrong self-checks, and signature checking (*keyring is not writable*) which is why `offline.conf` has `SigLevel Never`. The final baked image passed 12 of 12 checks in a fresh install. The keep-`/home` rebuild passed earlier with the same script.
