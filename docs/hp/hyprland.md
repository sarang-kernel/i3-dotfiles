---
title: "Hyprland setup"
parent: "HP desktop and server"
nav_order: 1
---

# Hyprland setup

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


Hyprland 0.55+ moved to a **Lua** configuration (hyprlang is being dropped). `~/.config/hypr/hyprland.lua` is only the entry point; each concern is a file in `conf/`. Validate any edit without restarting:

```bash
Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
```

(`Super+Shift+C` reloads with that validation built in.)

## Install and start

```bash
~/.config/hypr/install.sh      # one sudo pacman -Syu --needed … of the official packages (list in packages.txt)
~/.config/hypr/doctor.sh       # checks dependencies and validates the config
~/.config/hypr/report.sh       # on a problem: versions, config errors, logs, which shell parts are up -> ~/.cache/hypr/
start-hyprland                 # from a tty
```

`~/.bash_profile` and `~/.xinitrc` were deliberately left alone, so `startx` still gives the old i3 session. Optional autostart on tty1 (a line for `~/.bash_profile`, not `exec`, so a failed session drops back to the shell with the error visible; `touch ~/.no-hyprland` opts out). With greetd autologin (see [tuning](tuning.html)) the machine signs in by itself and locks the session at once.

## Files

| File | What it configures |
|---|---|
| `hyprland.lua` | Entry point: sets `package.path` and requires the files below in order |
| `conf/env.lua` | Environment: `XDG_CURRENT_DESKTOP=Hyprland`, Wayland-first toolkits (`GDK_BACKEND=wayland,x11`, `QT_QPA_PLATFORM=wayland;xcb`, `MOZ_ENABLE_WAYLAND`, Electron ozone hint), capitaine cursors at 24, `LIBVA_DRIVER_NAME=i965` for the Haswell iGPU, the ibus + mozc input method, `FILEMANAGER=thunar` and `TERMINAL=…/term.sh` |
| `conf/monitors.lua` | Panel `eDP-1` at its preferred mode, scale 1; any other display lands to the right at its preferred mode; notifications when one is connected or removed |
| `conf/look.lua` | Gaps 4/10, border 2 with a two-colour gradient, rounding 12 (squircle-ish), dim inactive 10 %, shadows, **2-pass kawase blur**, dwindle (default), master and scrolling layouts. Tuned for a Haswell iGPU: modest shadows, no looping effects |
| `conf/animations.lua` | Bezier and spring curves; windows spring (`glide`), popin for new windows, slide-fade workspaces. `borderangle` is off on purpose (it would redraw every frame) |
| `conf/input.lua` | US layout with `caps:super`, repeat 38/s after 280 ms, num lock on, touchpad natural scroll + tap + drag + disable-while-typing, gestures (3-finger swipe workspaces; Super + 3-finger down closes; 4-finger up scratchpad, down float; Super pinch zoom) |
| `conf/binds.lua` | All keybindings ([generated table](keybindings.html)) |
| `conf/rules.lua` | Window rules: suppress maximize events, fix XWayland drag focus, translucent terminals (`opacity 0.93 0.86`), floating utilities and dialogs, TUI popups, the drop-down terminal, picture-in-picture, and more |
| `conf/autostart.lua` | Session services, once per compositor start |
| `conf/colors.lua`, `conf/palette.lua` | **Generated** colours (see [Theming](theming.html)): do not edit by hand |
| `conf/user.lua` | Look presets from the settings hub (zen mode, transparency, gaps) |
| `conf/eco.lua` | Battery-saver overrides; **must be required last** |
| `hypridle.conf`, `hyprlock.conf`, `hyprsunset.conf` | Idle chain, lock screen (blurred live screenshot, avatar), night-light schedule. `hypridle.conf` has **no suspend-on-battery rule on purpose**, so a power cut does not take the server offline |
| `server.conf` | Which services count as "the server" |
| `webapps.conf` | `name|url` lines for web-app windows (`Super+Alt+B`) |
| `shaders/*.frag` | Screen shaders: `grayscale`, `deuteranopia`, `protanopia`, `tritanopia` (colour-blind simulation), `eink`, `paper`, `sepia`, `invert`, `redlight`, `crt`, `vignette` |
| `kitty/` | `kitty.conf` and generated `colors.conf` |
| `shell/` | Shell integration: `rice.bash` (prompt, fzf, man colours, eza, zoxide), `colors.sh`, `vt-palette.sh`, completion |
| `theme/` | The theme engine (see [Theming](theming.html)) |
| `system/` | Root-side tools (boot theme, server tuning, ssh lock-down, sudo window) |
| `scripts/` | Everything else; see [Script reference](script-reference.html) |

## What starts with the session (`conf/autostart.lua`)

On `hyprland.start`: import the Wayland environment into systemd and D-Bus, start the portals after a second (`portals.sh`) and `hyprpolkitagent`, set GTK/icon/cursor settings (`theme-init.sh`), start `awww-daemon` and the first wallpaper, start the **shell** (`shell.sh start`), `hypridle` and `hyprsunset`, the clipboard history recorders (`wl-paste --watch cliphist store`, text and image), `ibus-daemon`, **`power-watch.sh`** (eco mode on unplug) and **`ambient.sh`** (wallpaper timer, automatic light/dark, resource budget, server checks), and the `foot --server`. With `RICE_AUTOLOGIN` set it locks the session four seconds after start.

## Eco mode

`scripts/eco.sh toggle|on|off|auto-on|auto-off|status` (`Super+F2`). While the flag `~/.cache/hypr/eco` exists, `conf/eco.lua` switches off animations, dimming, blur and shadows. **Manual** eco is only ever turned off by me; **automatic** eco is set by `power-watch.sh` when the charger is unplugged and cleared on plug-in. The governor in `ambient.sh` can also turn it on (reason `governor`) when the shell uses too much CPU.

## Terminals

`scripts/term.sh` starts `footclient` against a single `foot --server` if foot is installed (one 20 MB process for every window, CPU-rendered), otherwise kitty. **kitty needs software GL on this laptop:** Hyprland on the Haswell iGPU advertises no ARGB8888 dmabuf format, so kitty's hardware EGL aborts (*Failed to find a suitable EGLConfig*). `scripts/kitty.sh` sets `LIBGL_ALWAYS_SOFTWARE=1` for kitty only; `touch ~/.config/hypr/kitty-hw` switches back to hardware GL after a Mesa or Hyprland fix.

## Notes

- Waybar 0.15's workspace module is display-only under a Lua config (clicks cannot dispatch), so scrolling over the window title or the clock switches workspaces; the `hypr` Quickshell shell has clickable workspaces.
- Haswell tip: if animations stutter on battery, raise `INTEL_GPU_MIN_FREQ_ON_BAT` in `/etc/tlp.conf` (for example to 500).
- Network is iwd and systemd-networkd, so the bar opens `impala` (Wi-Fi), `bluetui` and `wiremix` as floating TUIs (`scripts/tui.sh`, window class `tui-popup`).
- `.pacnew` care: keep my own `mkinitcpio.conf` (the new default drops the consolefont hooks) and `sshd_config` (the new default drops the hardening).
