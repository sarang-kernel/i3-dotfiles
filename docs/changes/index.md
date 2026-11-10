---
title: "What I changed and why"
nav_order: 10
description: "A dated log of changes and their reasons"
---

# What I changed and why

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


A log of the changes I made while stabilising and tuning these machines, with the reasoning, so I can undo or revisit any of them. Newest first. The detail of each piece is in the section it belongs to.

## 10 November 2026

- **Screenshots of everything, on a virtual screen.** The README pictures are taken on a throwaway Xvfb display so no real window or Wi-Fi name is in them. [How](../i3/screenshots.html).
- **Notepad on Super+N** (`scratch.sh`): a floating Neovim on `~/Documents/scratch.md` that autosaves. I made it because gedit segfaults in `libgedit-51.so` on this machine and spins a core for seconds on a normal start. [Details](../scripts/session.html#scratchsh).
- **Lock screen painted after the idle timeout.** The lock window sometimes did not appear until I moved the mouse. Findings: forcing a repaint from `lock.sh` (picom `SIGUSR1`) *caused* failures (3 of 8 runs) and was removed; `unredir-if-possible` is now off in both picom variants; `use-damage = false` was tried and reverted because it makes every frame a full redraw. A real idle timeout is the final test. [Compositor](../i3/compositor.html), [Lock screen](../i3/lock-screen.html).
- **`lag-now`** (`Super+Shift+F12`): a one-key snapshot for the intermittent lag, instead of a recorder that runs all the time. A recorder (`stall-watch`) was written, never started and then removed. [Details](../scripts/session.html#lag-now).
- **`rog-snappy.sh`:** the *Balanced* profile used the CPU energy preference `balance_power`, which keeps cores at 1.1-2.4 GHz until load has built up. Now `balance_performance`. [Tools](../rog-tune/tools.html#rog-snappysh).
- **`hp-boot-tune.sh` on the HP:** the health check restarted still-starting services, a persistent timer burned 3 minutes of CPU after every boot, and GRUB waited 10 s on a menu. Drop-ins and a shorter, hidden menu; nothing is restarted. [Boot and server tuning](../hp/tuning.html).
- **Neovim reviewed.** Two things documented but not wired up: the gitsigns hunk keymaps and completion. Left as they are, with the fixes written down. [Known issues](../nvim/troubleshooting.html).
- **Spotlight reviewed.** `Ctrl+C` is advertised as *copy* but closes the window (an earlier rule catches it). `Alt+Enter` copies. [Keys](../spotlight/keys.html#copying).

## 8-9 November 2026

- **Restore ISO built and tested.** A bootable Arch image that rebuilds the machine offline; a fresh-disk and a keep-`/home` restore both pass in a virtual machine, 12 of 12 checks on the final baked image. The recipe is published (no secrets), the ISO is in local copies only. [Restore ISO](../iso/).
- **hp-dash** (the HP's browser control center) built and tested with 66 automated checks and a headless-browser pass. [hp-dash](../hp/hp-dash.html).
- **READMEs rewritten in my own voice** and the recipe, `rog-tune` extras and the screenshot tooling added to the dotfiles repository.

## Just before that (early November 2026)

- **Boot stability.** Two failures: the greeter raced the GPU driver, and screen rotation failed once.
  - *Greeter race:* the optional `slimboot` part had removed `amdgpu` from the boot image, so the login screen sometimes started before the GPU. `slimboot` is retired (it refuses to run), `amdgpu` is back in the boot image (`MODULES=(amdgpu)`), and the greeter start script waits up to 15 s for the AMD card's panel (never the NVIDIA one) and falls back to a simple framebuffer. [rog-tune `greetd`](../rog-tune/rog-tune-parts.html).
  - *Rotation:* `autorotate.sh` now retries `monitor-sensor` with backoff when the sensor claim is refused, only records a rotation after `xrandr` succeeds, and looks the panel name up at run time (`eDP-1` or `eDP-2`). The same lookup is in `power-watch.sh` and `pen-setup.sh`. [autorotate](../scripts/power-display.html#autorotatesh).
- **Bluetooth keyboard** drops investigated with a whitelist-only capture (`bt-capture.sh`): the controller reported disconnect reason 0x08 (connection timeout). The root cause is not resolved. [Tools](../rog-tune/tools.html#bt-capturesh).

## Things I tried and dropped

| Idea | Why it went |
|---|---|
| `use-damage = false` in picom | Fixed the lock-screen repaint but costs a full-screen redraw and blur on every change |
| `SIGUSR1` poke from `lock.sh` | Made the lock fail to paint in 3 of 8 runs |
| A background stall recorder | One more thing running all the time; the on-demand `lag-now` snapshot is enough |
| gedit as the quick notepad | Crashes; replaced by the Neovim scratchpad |
| Disabling the XDG autostart entries one by one by hand | The Settings app's *Startup Apps* page does it with `Hidden=true` stubs |
