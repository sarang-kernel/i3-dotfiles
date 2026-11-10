---
title: "Install and layout"
parent: "i3 desktop"
nav_order: 1
---

# Install and layout

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


## Before you start

This is a *personal* setup for one laptop. It will install on another Arch machine, but the ASUS-specific parts (`asusctl` fan curves and keyboard light, the `nvidia_wmi_ec_backlight` device, the 2560×1600 165 Hz panel timings in `power-watch.sh`, the ELAN pen) will do nothing or complain. Read the scripts before running them.

## Packages

What I install first on Arch:

```bash
sudo pacman -S i3-wm polybar picom kitty rofi python-gobject gtk4 libadwaita libqalculate plocate ripgrep xss-lock xclip imagemagick
```

The scripts call many more programs; the complete list, with the script that needs each one, is on the generated [Dependencies page](../scripts/dependencies.html). Optional extras: `i3lock-color` (AUR) for the pretty lock screen (plain `i3lock` works too), and `greetd greetd-regreet sway` for the login screen.

## The user part: `install.sh`

```bash
git clone https://github.com/sarang-kernel/i3-dotfiles ~/Development/i3-dotfiles
cd ~/Development/i3-dotfiles
./install.sh
```

`install.sh` copies these folders into `~/.config` (anything it would replace is first copied to `~/.config-backup-<date>-<time>`):

`i3 polybar picom kitty rofi i3lock wallpaper-config yazi rmpc touchegg Thunar btop mpv cava qalculate gtk-3.0 gtk-4.0 scripts rog spotlight dunst htop autostart`

It also copies the systemd user units into `~/.config/systemd/user`, `chrome-flags.conf` into `~/.config`, and makes the scripts and `i3lock/lock.sh` executable. Then reload i3 (`Super+Shift+R`).
It never touches anything outside `~/.config`; the root-side parts are separate on purpose.

## The root part: rog-tune

```bash
sudo ./rog-tune/rog-tune.sh                      # dry run: every change as a diff
sudo ./rog-tune/rog-tune.sh --apply greetd speed # an example
```

See [rog-tune](../rog-tune/). Nothing in `install.sh` needs root.

## Repository layout

| Path | What it is |
|---|---|
| `i3/config`, `i3/toggle-touchpad.sh` | The window manager config and the touchpad toggle |
| `polybar/` | `config.ini` and three helper scripts (`bri-follow.sh`, `mic-follow.sh`, `iwd-status.sh`) |
| `picom/` | `picom-ac.conf` (blur) and `picom-bat.conf` (no blur); the live `picom.conf` is a symlink |
| `kitty/` | `kitty.conf` and `theme.conf` |
| `rofi/` | The old rofi launcher and theme; rofi still serves the window switcher and the key list |
| `i3lock/` | `lock.sh` and two avatar images from the previous lock screen |
| `scripts/` | The 32 helper scripts, Spotlight and Settings |
| `rog/settings.env` | My settings file |
| `rog-tune/` | The installers and root-side tuning (see its own section), plus `notes/` with measurements |
| `iso/` | The recipe for my offline restore ISO (see the ISO section) |
| `systemd/user/` | The sshfs mount units for the home server (`home-sarang-mnt-server.mount` / `.automount`) |
| `wallpaper-config/` | `wallpaper-cycle.sh` and the reverse |
| `apps/spotlight/` | A copy of the standalone [Spotlight repo](https://github.com/sarang-kernel/spotlight); the live copies are in `scripts/` |
| `spotlight/aliases` | My Spotlight shortcuts |
| `nvim/` | A git submodule that points at my Neovim repo |
| `autostart/` | `.desktop` stubs that switch unwanted XDG autostarts off |
| `btop cava dunst htop mpv qalculate rmpc touchegg yazi Thunar gtk-3.0 gtk-4.0 dconf` | Settings of other programs; see [Other app configs](other-apps.html) |
| `chrome-flags.conf` | Chrome/Chromium flags for hardware video decoding |
| `docs/` | This documentation site, its pictures (`docs/img`) and the screenshot tooling (`docs/make-screenshots`) |

The complete file-by-file list is the generated [File index](../reference/file-index.html).

## Updating

`git pull`, run `./install.sh` again (it backs up what it replaces), then `i3-msg restart`. If you changed scripts that the Spotlight daemon runs, `~/.config/scripts/rog-ui.sh restart` reloads it.

## Uninstalling

Restore the folder `~/.config-backup-*` that `install.sh` printed, or use `~/rog-tune/rog-lean-session.sh --undo` (user side) and `sudo ~/rog-tune/rog-tune.sh --undo` (root side).
