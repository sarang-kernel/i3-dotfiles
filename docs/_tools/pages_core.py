"""Site config, home page and the changes page."""
from common import *


def build():
    (SITE / "_config.yml").write_text("""title: Sarang's Linux setup
description: Documentation for my i3 desktop, Spotlight, Neovim, the restore ISO and the HP home server
remote_theme: just-the-docs/just-the-docs@v0.12.0
plugins:
  - jekyll-remote-theme
url: https://sarang-kernel.github.io
baseurl: /i3-dotfiles
search_enabled: true
search:
  heading_level: 2
  previews: 3
heading_anchors: true
enable_copy_code_button: true
color_scheme: dark
back_to_top: true
back_to_top_text: "Back to top"
footer_content: "My setup, written by me, for me, and for whoever finds it useful. No warranty: read a script before you run it."
aux_links:
  "i3-dotfiles on GitHub": "https://github.com/sarang-kernel/i3-dotfiles"
  "spotlight on GitHub": "https://github.com/sarang-kernel/spotlight"
  "nvim on GitHub": "https://github.com/sarang-kernel/nvim"
aux_links_new_tab: true
callouts:
  note:
    title: Note
    color: blue
  warning:
    title: Careful
    color: red
  tip:
    title: Tip
    color: green
exclude:
  - make-screenshots
  - Gemfile
  - README.md
""")

    write("index.md", fm("Home", None, 1, desc="Documentation for my Linux setup"), """# My Linux setup, documented

Hi. These are the docs for the things I built and tuned on my two Arch Linux laptops, written so that future-me (and anyone curious) can find out **what exists, how it works, how to change it and how to put it back**.
It is a *personal* setup, so read before you run: nothing here is a product, but everything has a dry run, an undo or a backup where it matters.

![My desktop](img/desktop.png)

## The machines

| Machine | What it is | Software |
|---|---|---|
| **ASUS ROG Flow X13** (Ryzen 9 7940HS, RTX 4050, 2560×1600 165 Hz) | My main PC | Arch Linux, **X11 + i3**, polybar, picom, my own Spotlight and Settings apps |
| **HP EliteBook 840 G1** (Core i5-4300U) | The **home server** and a normal laptop | Arch Linux, **Hyprland** (Lua config), Quickshell shell, hp-dash |

## Sections

| Section | What is in it |
|---|---|
| [i3 desktop](i3/) | Keybindings, windows and rules, autostart, polybar, compositor, terminal, lock screen, colours, other app configs, troubleshooting |
| [Spotlight](spotlight/) | My Spotlight-style launcher: every kind of query, every key, clipboard history, timers, deep search, internals |
| [Scripts](scripts/) | Every helper script explained (power, display, session, system), the Settings app, the 39 settings, dependencies, conventions |
| [rog-tune](rog-tune/) | The tuning installers: all root-side and user-side *parts*, the helper tools, backups and undo |
| [Restore ISO](iso/) | A bootable Arch image that rebuilds the laptop offline: how it is built, restored, tested and secured |
| [Neovim](nvim/) | The editor config: keymaps, plugins, language servers, Markdown, LaTeX, known issues |
| [HP desktop and server](hp/) | Hyprland setup, theming, swappable shell, the home server, hp-dash, boot tuning |
| [Reference](reference/) | The file index and other generated lists |
| [What I changed and why](changes/) | A dated log of the changes and the reasoning |

## How these docs are made (and why you can trust them)

I do not write reference tables by hand. A small generator reads the **real files** and writes the tables: the i3 keybindings come from `i3/config`, the Hyprland binds from `binds.lua`, the Neovim keymaps from the Lua files, the 39 settings from `settings.py`, the rog-tune *parts* from the headers of the scripts, the dependencies by scanning every script. The prose around them was written after reading the code, and where the code disagrees with a README or a comment I say so (see [Neovim known issues](nvim/troubleshooting.html)).
The generator also checks that every file in the repositories appears in the [file index](reference/file-index.html), and that every internal link resolves.

## How to read a page

- `Super` is the Windows key (on my keyboards it is also Caps Lock).
- A path starting with `~/.config/…` is on the machine; a path like `scripts/…` is in the `i3-dotfiles` repository.
- A code block is something you can paste. A *Known issue* is something I found while documenting and did not silently fix.

## The repositories

- [`sarang-kernel/i3-dotfiles`](https://github.com/sarang-kernel/i3-dotfiles): the i3 desktop, the scripts, rog-tune, the ISO recipe, and these docs (`docs/`).
- [`sarang-kernel/spotlight`](https://github.com/sarang-kernel/spotlight): Spotlight on its own.
- [`sarang-kernel/nvim`](https://github.com/sarang-kernel/nvim): the Neovim config.
- The HP's configuration is on the machine itself (`~/.config/hypr`, `~/.local/share/hp-dash`) and documented in the HP section.
""")

    write("changes/index.md", fm("What I changed and why", None, 10, desc="A dated log of changes and their reasons"), """# What I changed and why

{TOC}

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
""".replace("{TOC}", TOC))


if __name__ == "__main__":
    build()
