---
title: "Other app configs"
parent: "i3 desktop"
nav_order: 11
---

# Other app configs

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


Settings for programs that are not part of the desktop proper. They are copied by `install.sh`.

| Folder / file | Program | What is in it |
|---|---|---|
| `btop/btop.conf` | btop | The task monitor's config (286 lines, mostly defaults with my theme and update rate). *The ISO leaves btop out on purpose* (see below) |
| `cava/` | cava (audio visualiser) | `config`, two colour themes (`solarized_dark`, `tricolor`) and five fragment shaders (`bar_spectrum`, `eye_of_phi`, `northern_lights`, `spectrogram`, `winamp_line_style_spectrum`) with a shared vertex shader |
| `dunst/dunstrc` | dunst | Notification daemon: top-right, 5 at a time, Catppuccin colours, Papirus-Dark icons. **Not in use today:** the `quiet` part of `rog-lean-session.sh` parks the notification daemon (no popups at all) |
| `dconf/user` | GNOME dconf | A binary dconf database (GVariant) with settings of GNOME apps (file-roller, Nautilus-style file chooser, …). Not human-readable: `dconf dump /` shows its contents |
| `gtk-3.0`, `gtk-4.0` | GTK | See [Colours, accent and fonts](theme.html) |
| `htop/htoprc` | htop | 64 lines of layout and meters |
| `mpv/mpv.conf` | mpv | One live line: `input-ipc-server=~/.cache/mpv-ipc`, so cinema mode can ask mpv for the film's exact frame rate |
| `qalculate/qalc.cfg` | qalc | Settings for `qalc`, the calculator behind Spotlight's maths and unit conversion |
| `rmpc/` | rmpc (MPD client) | `config.ron` and a pywal colour file |
| `rofi/` | rofi | `catppuccin-mocha.rasi` (theme), `config.rasi`, `powermenu.rasi`, plus the old launcher scripts (below) |
| `touchegg/touchegg.conf` | Touchégg | Touchpad gestures: **3-finger swipe left/right** = next/previous workspace, **3-finger swipe up** = fullscreen, **3-finger swipe down** = floating toggle, **4-finger swipes** = mouse buttons (browser back/forward style), **2-finger pinch** = zoom keys |
| `Thunar/` | Thunar | `uca.xml` (one custom action: *Open Terminal Here* via `exo-open`) and `accels.scm` (a keyboard shortcut dump) |
| `yazi/` | yazi | `yazi.toml` opens PDFs with zathura; `package.toml` is empty. *Left out of the ISO on purpose* |
| `autostart/*.desktop` | XDG autostart | Four `Hidden=true` stubs: `picom`, `nm-applet`, GNOME's disk-utility notifier, the AT-SPI bus. They override entries in `/etc/xdg/autostart` |
| `chrome-flags.conf` | Chrome / Chromium | `--enable-features=AcceleratedVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxZeroCopyGL,VaapiIgnoreDriverChecks` (hardware video decoding) |
| `systemd/user/home-sarang-mnt-server.{mount,automount}` | systemd user units | An sshfs mount of the home server (`hp-server:/home/sarang` on `~/mnt/server`) with reconnect options. The `automount` unit failed at every login at one point, so the `automount` part of `rog-lean-session.sh` can disable it |
| `wallpaper-config/` | scripts | Documented under [System tools](../scripts/system.html#wallpaper-cyclesh) |
| `spotlight/aliases` | Spotlight | My shortcut file: [Aliases and data files](../spotlight/data-files.html) |

## The old rofi launcher

Before my own Spotlight, `Super+D` opened a rofi-based launcher: `rofi/spotlight.sh` (an apps cache, recent files, a tiny calculator and `plocate` search), `rofi/spotlight-v3.py` (a rofi script-mode launcher), `rofi/powermenu.sh` and `powermenu.rasi`.
They are **kept for reference but unused**: the keybindings now point at the native Spotlight, and `Super+Tab` (window switcher) and the key list (`keys.sh`) are the only things rofi still does. `rofi/catppuccin-mocha.rasi.bak` is a stale backup.

## Why zathura, btop and yazi are special

My restore ISO (see the [ISO section](../iso/)) deliberately leaves out zathura, btop and yazi, so those three configs exist in the repo but the programs are not guaranteed to be installed. `vimtex` in Neovim is configured to use zathura; install it again if you want the PDF viewer.
