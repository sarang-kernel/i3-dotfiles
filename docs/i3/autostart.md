---
title: "Autostart and session"
parent: "i3 desktop"
nav_order: 4
---

# Autostart and session

Everything below is an `exec` or `exec_always` line in `i3/config`. **`exec`** runs once when i3 starts; **`exec_always`** runs again on every reload (`Super+Shift+C`) and restart (`Super+Shift+R`), which is why those scripts all kill their previous copy first (see [Script conventions](../scripts/conventions.html)).

The last column says what each line is for.

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


## The lines

| When | Command | What it is for |
|---|---|---|
| once at login | `systemctl --user import-environment DISPLAY XAUTHORITY DBUS_SESSION_BUS_ADDRESS XDG_CURRENT_DESKTOP` | Hands DISPLAY, the D-Bus address and friends to systemd user services, so they can talk to my session |
| once at login | `dbus-update-activation-environment --systemd DISPLAY XAUTHORITY DBUS_SESSION_BUS_ADDRESS XDG_CURRENT_DESKTOP` | Same for D-Bus-activated programs (portals, notification daemons) |
| once at login | `sh -c 'export XDG_CURRENT_DESKTOP=i3'` | Tells portals and apps they are running under i3 |
| once at login | `picom --config ~/.config/picom/picom.conf` | The compositor: translucency and blur (config is a symlink, see Compositor page) |
| every start and reload | `sh -c "killall -q polybar; while pgrep -u $(id -u) -x polybar >/dev/null; do sleep 0.05; done; exec polybar -c ~/.config/polybar/config.ini toph"` | The bar. Kills any running copy first so a reload never leaves two bars |
| once at login | `sh -c "~/.config/wallpaper-config/wallpaper-cycle.sh"` | Sets the wallpaper (day/night folders) once per login; a reload keeps the current one |
| every start and reload | `~/.config/scripts/autorotate.sh` | Follows the accelerometer: rotates the panel, touchscreen and pen together |
| once at login | `~/.config/scripts/pen-setup.sh` | Maps the ASUS stylus and touchscreen to the internal panel and sets pen buttons |
| once at login | `sh -c "sleep 1; xinput set-prop 'ASUF1204:00 2808:0201 Touchpad' 'libinput Natural Scrolling Enabled' 1"` | Natural scrolling on the touchpad (the Settings app later overrides this through input-apply.sh) |
| once at login | `xinput set-prop "ASUF1204:00 2808:0201 Touchpad"  "libinput Tapping Button Mapping Enabled" 1 0` | Tap to click: one finger = left, two fingers = right |
| every start and reload | `xsetroot -cursor_name left_ptr` | Normal arrow cursor on the empty desktop |
| every start and reload | `~/.config/scripts/power-watch.sh` | Watches the power source (upower) and applies performance mode, refresh rate, lock timers and the compositor variant |
| every start and reload | `~/.config/scripts/nightlight.sh daemon` | Applies the night tint on schedule (wakes every 5 minutes or when told) |
| once at login | `xss-lock --transfer-sleep-lock -- ~/.config/i3lock/lock.sh` | Runs the lock screen when the idle timer fires and before suspend |
| every start and reload | `~/.config/scripts/autocaffeine.sh` | Keeps the screen on while something is fullscreen or the microphone is in use |
| every start and reload | `~/.config/scripts/rog-ui.sh start` | Starts the resident Spotlight process so Super+D is instant |
| every start and reload | `~/.config/scripts/input-apply.sh` | Applies touchpad, pointer and key-repeat settings from the Settings app |
| once at login | `~/.config/scripts/login-apply.sh` | Once per login: optional muted mic, restore the brightness I last chose |
| every start and reload | `python3 ~/.config/scripts/display-agent.py` | Adaptive refresh rate, cinema mode, camera-in-use flag and optional workspace icons |
| every start and reload | `~/.config/scripts/wallpaper-timer.sh` | Re-creates the optional automatic wallpaper timer from Settings |


## What else starts at login

- `xss-lock --transfer-sleep-lock -- ~/.config/i3lock/lock.sh` (the `exec` line marked *idle*): locks the screen when the idle timer fires and before suspend. See [Lock screen](lock-screen.html).
- The **resident Spotlight process** is started by `rog-ui.sh start`, so it is already in memory when I press Super+D. See [Spotlight internals](../spotlight/internals.html).
- **XDG autostart** entries: the repo's `autostart/` folder holds four `.desktop` stubs that switch things off (`picom`, `nm-applet`, GNOME's disk-notify daemon, the AT-SPI bus). They are `Hidden=true` copies that override the system entries in `/etc/xdg/autostart`; the Settings app's *Startup Apps* page edits the same kind of file.
- **Greeter and root-side services** are not part of i3 at all; they are in [rog-tune](../rog-tune/).
