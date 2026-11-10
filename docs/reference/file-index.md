---
title: "File index"
parent: "Reference"
nav_order: 1
description: "Every file, what it is and where it is documented"
---

# File index

Every tracked file of the three repositories and the HP's configuration, with what it is and where it is documented. It exists so that **nothing is missed**: a check script compares this list with the repositories on every build of the docs.

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


## i3-dotfiles (260 files)

| File | What it is | Documented |
|---|---|---|
| `.gitignore` | Files git ignores (`*.bak*`, `__pycache__`, …) | [docs](../i3/install.html) |
| `.gitmodules` | Declares the nvim submodule | [docs](../nvim/) |
| `README.md` | What it looks like | [docs](../) |
| `Thunar/accels.scm` | Thunar custom action and shortcuts | [docs](../i3/other-apps.html) |
| `Thunar/uca.xml` | Thunar custom action and shortcuts | [docs](../i3/other-apps.html) |
| `apps/spotlight/README.md` | Spotlight for i3 | [docs](../spotlight/) |
| `apps/spotlight/alarm.py` | the window a Spotlight timer or reminder shows when it rings. Stays until I dismiss it (Enter / Esc); S snoozes 5 minutes. | [docs](../spotlight/) |
| `apps/spotlight/install.sh` | Installs Spotlight into ~/.config/scripts (existing copies are saved as *.old) and prints the i3 lines to add. | [docs](../spotlight/) |
| `apps/spotlight/power-menu.py` | power menu (Super+Escape). One row of big tiles: Lock, Log out, Sleep, Hibernate, Restart, Shut down. | [docs](../spotlight/) |
| `apps/spotlight/rg-pre.sh` | ripgrep --pre helper for Spotlight's deep search: PDF text is extracted once and cached (by path + mtime) | [docs](../spotlight/) |
| `apps/spotlight/rog-ui.sh` | client for the resident Spotlight/Settings process (it starts at login, so opening is near-instant). | [docs](../spotlight/) |
| `apps/spotlight/spotlight.py` | Resident mode: Spotlight is built once and shown on request (~instant); commands arrive on a FIFO. (Settings is NOT kept in memory.) | [docs](../spotlight/) |
| `autostart/at-spi-dbus-bus.desktop` | XDG autostart stub that switches an entry off | [docs](../i3/autostart.html) |
| `autostart/nm-applet.desktop` | XDG autostart stub that switches an entry off | [docs](../i3/autostart.html) |
| `autostart/org.gnome.SettingsDaemon.DiskUtilityNotify.desktop` | XDG autostart stub that switches an entry off | [docs](../i3/autostart.html) |
| `autostart/picom.desktop` | XDG autostart stub that switches an entry off | [docs](../i3/autostart.html) |
| `btop/btop.conf` | ? Config file for btop v.1.4.7 | [docs](../i3/other-apps.html) |
| `cava/config` | # Configuration file for CAVA. | [docs](../i3/other-apps.html) |
| `cava/shaders/bar_spectrum.frag` | bar values. defaults to left channels first (low to high), then right (high to low). | [docs](../i3/other-apps.html) |
| `cava/shaders/eye_of_phi.frag` | this shader was stolen from shadertoy user ChunderFPV | [docs](../i3/other-apps.html) |
| `cava/shaders/northern_lights.frag` | bar values. defaults to left channels first (low to high), then right (high to low). | [docs](../i3/other-apps.html) |
| `cava/shaders/pass_through.vert` | Input vertex data, different for all executions of this shader. | [docs](../i3/other-apps.html) |
| `cava/shaders/spectrogram.frag` | bar values. defaults to left channels first (low to high), then right (high | [docs](../i3/other-apps.html) |
| `cava/shaders/winamp_line_style_spectrum.frag` | Emulate the "line style" spectrum analyzer from Winamp 2. | [docs](../i3/other-apps.html) |
| `cava/themes/solarized_dark` | cava visualiser config, themes and shaders | [docs](../i3/other-apps.html) |
| `cava/themes/tricolor` | cava visualiser config, themes and shaders | [docs](../i3/other-apps.html) |
| `chrome-flags.conf` | enable-features=AcceleratedVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxZeroCopyGL,VaapiIgnoreDriverChecks | [docs](../i3/other-apps.html) |
| `dconf/user` | GNOME dconf database | [docs](../i3/other-apps.html) |
| `docs/make-screenshots/README.md` | make-screenshots | [docs](../i3/screenshots.html) |
| `docs/make-screenshots/demo.sh` | Tooling for the README pictures | [docs](../i3/screenshots.html) |
| `docs/make-screenshots/env.sh` | Tooling for the README pictures | [docs](../i3/screenshots.html) |
| `docs/make-screenshots/inner.sh` | Tooling for the README pictures | [docs](../i3/screenshots.html) |
| `docs/make-screenshots/prep.sh` | Builds the three throwaway configs the virtual screen needs, from my real ones: an i3 config with every autostart line removed (so | [docs](../i3/screenshots.html) |
| `docs/make-screenshots/scene.sh` | Tooling for the README pictures | [docs](../i3/screenshots.html) |
| `docs/make-screenshots/start.sh` | Tooling for the README pictures | [docs](../i3/screenshots.html) |
| `dunst/dunstrc` | dunst — Catppuccin Mocha, square corners (no compositor here), progress bar for the volume/brightness OSD | [docs](../i3/other-apps.html) |
| `gtk-3.0/settings.ini` | GTK 3 settings | [docs](../i3/theme.html) |
| `gtk-4.0/settings.ini` | GTK 4 settings | [docs](../i3/theme.html) |
| `htop/htoprc` | Beware! This file is rewritten by htop when settings are changed in the interface. | [docs](../i3/other-apps.html) |
| `i3/config` | This file has been auto-generated by i3-config-wizard(1). | [docs](../i3/keybindings.html) |
| `i3/toggle-touchpad.sh` | toggle-touchpad: turn the touchpad on or off (bound to the XF86TouchpadToggle key in i3/config). | [docs](../scripts/session.html#toggle-touchpadsh) |
| `i3lock/avatar/avatar.eps` | Avatar image from an earlier lock screen (not used by the current script) | [docs](../i3/lock-screen.html) |
| `i3lock/avatar/avatar.jpg` | Avatar image from an earlier lock screen (not used by the current script) | [docs](../i3/lock-screen.html) |
| `i3lock/lock.sh` | lock with the current wallpaper (blurred and darkened by login-bg.sh; i3lock only reads PNG). | [docs](../i3/lock-screen.html) |
| `install.sh` | Copies these dotfiles into ~/.config (existing files are saved to ~/.config-backup-<date> first). | [docs](../i3/install.html) |
| `iso/README.md` | Restore ISO build, install and test script | [docs](../iso/) |
| `iso/build.sh` | collects the root-only system state and builds the ISO. Run prepare.sh first (as my user). | [docs](../iso/) |
| `iso/lists/aur.txt` | Package lists for the ISO | [docs](../iso/contents.html) |
| `iso/lists/explicit-all.txt` | Package lists for the ISO | [docs](../iso/contents.html) |
| `iso/lists/explicit-native.txt` | Package lists for the ISO | [docs](../iso/contents.html) |
| `iso/lists/native-all.txt` | Package lists for the ISO | [docs](../iso/contents.html) |
| `iso/lists/native.txt` | Package lists for the ISO | [docs](../iso/contents.html) |
| `iso/lists/removed.txt` | Package lists for the ISO | [docs](../iso/contents.html) |
| `iso/offline.conf` | pacman configuration used by rog-restore (pacstrap -C): only the repository on this ISO, no network. | [docs](../iso/) |
| `iso/overlay/etc/X11/xorg.conf.d/00-keyboard.conf` | Written by systemd-localed(8), read by systemd-localed and Xorg. It's | [docs](../iso/contents.html) |
| `iso/overlay/etc/X11/xorg.conf.d/30-touchpad.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/X11/xorg.conf.d/40-libinput.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/ananicy.d/00-rog/rog.rules` | background work yields to the desktop | [docs](../iso/contents.html) |
| `iso/overlay/etc/asusd/asusd.ron` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/asusd/aura_19b6.ron` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/asusd/fan_curves.ron` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/avahi/avahi-daemon.conf` | This file is part of avahi. | [docs](../iso/contents.html) |
| `iso/overlay/etc/bluetooth/main.conf` | Default adapter name | [docs](../iso/contents.html) |
| `iso/overlay/etc/default/earlyoom` | Generated by ~/rog-tune/rog-tune.sh | [docs](../iso/contents.html) |
| `iso/overlay/etc/default/grub` | GRUB boot loader configuration | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/10-hinting-slight.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/10-scale-bitmap-fonts.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/10-yes-antialias.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/11-lcdfilter-default.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/20-unhint-small-vera.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/30-metric-aliases.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/40-nonlatin.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/45-generic.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/45-latin.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/46-noto-sans.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/46-noto-serif.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/48-guessfamily.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/48-spacing.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/49-sansserif.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/50-user.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/51-local.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/60-generic.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/60-latin.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/65-fonts-persian.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/65-nonlatin.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/66-noto-sans.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/66-noto-serif.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/69-unifont.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/80-delicious.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/fonts/conf.d/90-synthetic.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/greetd/config.toml` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/greetd/regreet.css` | warm amber / chalk login screen | [docs](../iso/contents.html) |
| `iso/overlay/etc/greetd/regreet.toml` | (edit freely; see `man regreet`) | [docs](../iso/contents.html) |
| `iso/overlay/etc/greetd/sway.conf` | a bare sway that only hosts the greeter and follows the screen orientation | [docs](../iso/contents.html) |
| `iso/overlay/etc/gtk-3.0/settings.ini` | dark defaults for the login screen (your own ~/.config/gtk-3.0 overrides this) | [docs](../iso/contents.html) |
| `iso/overlay/etc/hostname` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/hosts` | Static table lookup for hostnames. | [docs](../iso/contents.html) |
| `iso/overlay/etc/initcpio/conf.d/resume.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/iwd/main.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/lightdm/lightdm.conf.d/50-rog.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/locale.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/locale.gen` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/localtime` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/makepkg.conf.d/rog-speed.conf` | (speed): AUR / dkms builds use every core | [docs](../iso/contents.html) |
| `iso/overlay/etc/mkinitcpio.conf` | The following modules are loaded before any boot hooks are | [docs](../iso/contents.html) |
| `iso/overlay/etc/mkinitcpio.d/linux.preset` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/modprobe.d/nvidia-pm.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/modprobe.d/rog-blacklist.conf` | nothing here uses these | [docs](../iso/contents.html) |
| `iso/overlay/etc/modprobe.d/rog-nvidia-sleep.conf` | keep the GPU's video memory across suspend/hibernate (needs the nvidia-* sleep services) | [docs](../iso/contents.html) |
| `iso/overlay/etc/modules-load.d/rog-bbr.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/nsswitch.conf` | Name Service Switch configuration file. | [docs](../iso/contents.html) |
| `iso/overlay/etc/pacman.conf` | /etc/pacman.conf | [docs](../iso/contents.html) |
| `iso/overlay/etc/pacman.d/hooks/00-rog-restore.hook` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/pacman.d/mirrorlist` | ############################################################################### | [docs](../iso/contents.html) |
| `iso/overlay/etc/shells` | Pathnames of valid login shells. | [docs](../iso/contents.html) |
| `iso/overlay/etc/sysctl.d/90-rog.conf` | swap is zram (compressed RAM): cheap, so prefer it over dropping page cache (kernel docs / Arch wiki: >100 is fine for zram) | [docs](../iso/contents.html) |
| `iso/overlay/etc/sysctl.d/91-rog-net.conf` | BBR congestion control + fq pacing (better throughput on lossy Wi-Fi) | [docs](../iso/contents.html) |
| `iso/overlay/etc/sysctl.d/92-rog-speed.conf` | (speed): latency-oriented, no security trade-offs | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/coredump.conf.d/10-rog.conf` | do not write core dumps | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/journald.conf.d/50-rog.conf` | flush to disk every 5 minutes instead of every few seconds (fewer SSD wakeups) | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/logind.conf` | This file is part of systemd. | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/logind.conf.d/50-rog-lid.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/resolved.conf.d/90-rog.conf` | no LLMNR / mDNS listeners (unicast DNS is unchanged) | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/sleep.conf` | This file is part of systemd. | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/sleep.conf.d/50-rog.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/system/autovt@.service` | SPDX-License-Identifier: LGPL-2.1-or-later | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/system/bluetooth.target.wants/bluetooth.service` | WatchdogSec=10 | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/system/dbus-org.bluez.service` | WatchdogSec=10 | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/system/dbus-org.freedesktop.resolve1.service` | SPDX-License-Identifier: LGPL-2.1-or-later | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/system/dbus-org.freedesktop.timesync1.service` | SPDX-License-Identifier: LGPL-2.1-or-later | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/system/default.target` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/system/display-manager.service` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/system/getty.target.wants/getty@tty1.service` | SPDX-License-Identifier: LGPL-2.1-or-later | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/system/greetd.service.d/rog.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/system/multi-user.target.wants/iwd.service` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/system/multi-user.target.wants/remote-fs.target` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/system/multi-user.target.wants/sshd.service` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/system/plocate-updatedb.service.d/10-rog.conf` | the nightly file index (8 s of full-speed I/O today) runs at idle priority | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/system/plocate-updatedb.timer.d/override.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/system/rog-health.service` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/system/rog-health.timer` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/system/sockets.target.wants/systemd-resolved-monitor.socket` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/system/sockets.target.wants/systemd-resolved-varlink.socket` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/system/sockets.target.wants/systemd-userdbd.socket` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/system/sysinit.target.wants/systemd-resolved.service` | SPDX-License-Identifier: LGPL-2.1-or-later | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/system/sysinit.target.wants/systemd-timesyncd.service` | SPDX-License-Identifier: LGPL-2.1-or-later | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/system/timers.target.wants/fstrim.timer` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/system/wowlan-enable.service` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/system.conf.d/10-rog.conf` | a hung service no longer delays shutdown by 90 s | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/user/graphical-session-pre.target.wants/xdg-user-dirs.service` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/user/pipewire-session-manager.service` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/user/pipewire.service.wants/wireplumber.service` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/user/sockets.target.wants/p11-kit-server.socket` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/user/sockets.target.wants/pipewire-pulse.socket` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/user/sockets.target.wants/pipewire.socket` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/user/xdg-desktop-portal-gtk.service.d/rog-greeter.conf` | (tidy): the GTK portal backend needs a display, which the login-screen user's manager does not have | [docs](../iso/contents.html) |
| `iso/overlay/etc/systemd/zram-generator.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/texmf/web2c/fmtutil.cnf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/texmf/web2c/updmap.cfg` | $Id: updmap-hdr.cfg 54473 2020-03-22 10:53:53Z hironobu $ | [docs](../iso/contents.html) |
| `iso/overlay/etc/tmpfiles.d/rog-thp.conf` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/tpm2-tss/fapi-profiles/P_ECCP384SHA384.json` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/tpm2-tss/fapi-profiles/P_RSA3072SHA384.json` | A file of my /etc (or /usr/local) override that goes into the restore ISO | [docs](../iso/contents.html) |
| `iso/overlay/etc/udev/rules.d/80-nvidia-pm.rules` | (from the Arch wiki's NVIDIA runtime D3 rules) | [docs](../iso/contents.html) |
| `iso/overlay/etc/udev/rules.d/81-rog-pm.rules` | re-apply PCI power saving whenever the power source changes (and once at boot, when the adapter is announced) | [docs](../iso/contents.html) |
| `iso/overlay/etc/vconsole.conf` | Written by systemd-localed(8) or systemd-firstboot(1), read by systemd-localed | [docs](../iso/contents.html) |
| `iso/overlay/etc/xdg/reflector/reflector.conf` | the fastest 20 https mirrors that synced in the last 12 hours (no country is assumed) | [docs](../iso/contents.html) |
| `iso/overlay/usr/local/lib/rog/greeter-brightness.sh` | Generated by ~/rog-tune/rog-tune.sh: run as root before the greeter. A screen left at a few percent looks black: lift it to 45 % if below 30 %. | [docs](../iso/contents.html) |
| `iso/overlay/usr/local/lib/rog/greeter-rotate-sway.sh` | Generated by ~/rog-tune/rog-tune.sh: rotate the login screen (touch follows automatically) whenever the accelerometer says so. | [docs](../iso/contents.html) |
| `iso/overlay/usr/local/lib/rog/greeter-rotate.sh` | Generated by ~/rog-tune/rog-tune.sh: rotate the LOGIN screen (panel + touch + pen) to match the accelerometer. | [docs](../iso/contents.html) |
| `iso/overlay/usr/local/lib/rog/greeter-start.sh` | Generated by ~/rog-tune/rog-tune.sh: run ReGreet inside sway on the AMD GPU (the NVIDIA card stays asleep). | [docs](../iso/contents.html) |
| `iso/overlay/usr/local/lib/rog/health.sh` | Generated by ~/rog-tune/rog-tune.sh: write a short SSD health report for Settings -> System. | [docs](../iso/contents.html) |
| `iso/overlay/usr/local/lib/rog/pm-apply.sh` | Generated by ~/rog-tune/rog-tune.sh: PCI runtime power management follows the power source (udev runs this on every plug/unplug and at boot). | [docs](../iso/contents.html) |
| `iso/overlay/usr/local/lib/rog/restore-point.sh` | Generated by ~/rog-tune/rog-tune.sh: save a restore point before pacman changes anything. Never fails the transaction. | [docs](../iso/contents.html) |
| `iso/overlay/usr/local/lib/rog/x11-session.sh` | Generated by ~/rog-tune/rog-tune.sh: ReGreet hands the chosen X session here; start X the same way as a tty login (reads ~/.xinitrc). | [docs](../iso/contents.html) |
| `iso/prepare.sh` | work/repo          offline package repository (every installed package at its installed version; AUR ones repacked from the installed files) | [docs](../iso/) |
| `iso/profile-overlay/airootfs/etc/motd` | archiso profile additions | [docs](../iso/build.html) |
| `iso/profile-overlay/airootfs/etc/systemd/system/rog-test-live.service` | archiso profile additions | [docs](../iso/build.html) |
| `iso/profile-overlay/profiledef.sh` | archiso profile additions | [docs](../iso/build.html) |
| `iso/publish.sh` | stages the recipe (NO secrets, NO ISO) in the dotfiles clone and scans it. Does not commit. | [docs](../iso/) |
| `iso/recover-from-github.md` | Plan B: rebuilding from this repository only | [docs](../iso/) |
| `iso/rog-restore` | rog-restore: rebuild this ASUS ROG Flow X13 from the offline snapshot on this ISO. | [docs](../iso/) |
| `iso/rog-test-live` | automatic test hook of the ISO: only runs when the kernel command line has rog_test=<scenario> (qemu tests), never on real hardware | [docs](../iso/) |
| `iso/scan-secrets.sh` | scan-secrets.sh DIR: refuse to publish if DIR looks like it holds keys, passwords or tokens. Exit 1 on any hit. | [docs](../iso/) |
| `iso/selftest.sh` | runs once on the first boot of a TEST restore (virtual machine) and reports on the serial console, then powers off | [docs](../iso/) |
| `iso/test-qemu.sh` | boots the built ISO in a virtual machine and runs the restore. | [docs](../iso/) |
| `iso/tools/repack-installed.py` | Rebuild an installable .pkg.tar.zst from a package that is ALREADY INSTALLED (AUR packages cannot be rebuilt reliably: upstream | [docs](../iso/build.html) |
| `kitty/kitty.conf` | bold_font        auto | [docs](../i3/terminal.html) |
| `kitty/theme.conf` | ## name:     Catppuccin Mocha 🌿 | [docs](../i3/terminal.html) |
| `mpv/mpv.conf` | rog-tune: lets cinema mode ask mpv for the video's exact frame rate | [docs](../i3/other-apps.html) |
| `picom/picom-ac.conf` | rog-tune: picom for Hyprland-style translucency: windows with alpha (kitty, rofi, polybar) show the blurred wallpaper behind them. | [docs](../i3/compositor.html) |
| `picom/picom-bat.conf` | rog-tune: picom on battery / in Quiet mode: translucent but no blur and no dimming, so the GPU stays near idle. | [docs](../i3/compositor.html) |
| `picom/picom.conf` | rog-tune: picom for Hyprland-style translucency: windows with alpha (kitty, rofi, polybar) show the blurred wallpaper behind them. | [docs](../i3/compositor.html) |
| `polybar/config.ini` | The bar | [docs](../i3/polybar.html) |
| `polybar/scripts/bri-follow.sh` | polybar brightness indicator. No polling processes: reads sysfs with shell builtins and waits on a private fifo. | [docs](../i3/polybar.html#helper-scripts-polybarscripts) |
| `polybar/scripts/iwd-status.sh` | iwd-status: polybar network module. Prints the connected network name (or "Disconnected") for the interface below. | [docs](../i3/polybar.html#helper-scripts-polybarscripts) |
| `polybar/scripts/mic-follow.sh` | polybar mic indicator, event driven (no polling). Always visible: quiet grey = live, red = muted. Click toggles. | [docs](../i3/polybar.html#helper-scripts-polybarscripts) |
| `qalculate/qalc.cfg` | qalc settings | [docs](../i3/other-apps.html) |
| `rmpc/config.ron` | rmpc (MPD client) config | [docs](../i3/other-apps.html) |
| `rmpc/pywal16.ron` | rmpc (MPD client) config | [docs](../i3/other-apps.html) |
| `rofi/catppuccin-mocha.rasi` | Spotlight-style Rofi theme (Catppuccin Mocha-ish) | [docs](../i3/other-apps.html#the-old-rofi-launcher) |
| `rofi/catppuccin-mocha.rasi.bak` | rofi theme, and the old rofi launcher kept for reference | [docs](../i3/other-apps.html#the-old-rofi-launcher) |
| `rofi/config.rasi` | configuration{ | [docs](../i3/other-apps.html#the-old-rofi-launcher) |
| `rofi/powermenu.rasi` | powermenu.rasi | [docs](../i3/other-apps.html#the-old-rofi-launcher) |
| `rofi/powermenu.sh` | ───────────────────────────────────────────────────────────────── | [docs](../i3/other-apps.html#the-old-rofi-launcher) |
| `rofi/spotlight-v3.py` | rofi theme, and the old rofi launcher kept for reference | [docs](../i3/other-apps.html#the-old-rofi-launcher) |
| `rofi/spotlight.sh` | rofi theme, and the old rofi launcher kept for reference | [docs](../i3/other-apps.html#the-old-rofi-launcher) |
| `rog/settings.env` | written by settings.py; sourced by the scripts in ~/.config/scripts | [docs](../scripts/settings-reference.html) |
| `rog-tune/bt-capture.sh` | Records only Bluetooth connection events (connect, disconnect + reason, link timing, scanning). A whitelist keeps every data line out, so typed keys n | [docs](../rog-tune/tools.html) |
| `rog-tune/ferdium-lean.sh` | Trim Ferdium's idle cost. Changes only settings, not my services or logins, and keeps a backup. | [docs](../rog-tune/tools.html) |
| `rog-tune/notes/baseline.txt` | Measurements: baseline report and the power comparison | [docs](../rog-tune/tools.html) |
| `rog-tune/notes/power-compare.txt` | Measurements: baseline report and the power comparison | [docs](../rog-tune/tools.html) |
| `rog-tune/power-compare.sh` | Measure real battery draw (watts). UNPLUG the charger first, then leave the laptop alone while it runs: screen on, nothing open that | [docs](../rog-tune/tools.html) |
| `rog-tune/rog-clean.sh` | Throw away regenerable caches on rog (no sudo). Dry run by default: shows sizes. | [docs](../rog-tune/tools.html) |
| `rog-tune/rog-debloat.sh` | Package bloat on rog. Lists what each group would remove (with sizes); removes only with --apply (asks pacman to confirm). | [docs](../rog-tune/tools.html) |
| `rog-tune/rog-lean-session.sh` | Session-side trimming + quality of life for rog (no sudo). Dry run by default; --undo restores everything it touched. | [docs](../rog-tune/lean-session-parts.html) |
| `rog-tune/rog-refresh.sh` | The panel runs at 165 Hz; most desktop work looks the same at 60 and costs much less (compositor, GPU, heat, fans). | [docs](../rog-tune/tools.html) |
| `rog-tune/rog-report.sh` | What is this machine spending? Run it before and after a change and compare. | [docs](../rog-tune/tools.html) |
| `rog-tune/rog-snappy.sh` | rog-snappy: make the CPU react faster (run with sudo). asusd sets the "Balanced" profile to the energy preference balance_power, which | [docs](../rog-tune/tools.html) |
| `rog-tune/rog-tune.sh` | Root-side tuning for the ROG Flow X13. Dry run by default; backs up before changing; --undo restores. | [docs](../rog-tune/rog-tune-parts.html) |
| `rog-tune/vaapi-check.sh` | is hardware video decoding available? Needs libva-utils (sudo pacman -S libva-utils). Read-only. | [docs](../rog-tune/tools.html) |
| `scripts/accent.sh` | apply the accent colour where Spotlight/Settings cannot reach: the bar's active workspace and the focused window's border. | [docs](../scripts/) |
| `scripts/alarm.py` | the window a Spotlight timer or reminder shows when it rings. Stays until I dismiss it (Enter / Esc); S snoozes 5 minutes. | [docs](../scripts/) |
| `scripts/autocaffeine.sh` | automatic caffeine. The screen stays on and unlocked while a window is fullscreen on the visible workspace (video, | [docs](../scripts/) |
| `scripts/autorotate.sh` | follow the accelerometer. Panel + touchscreen + pen rotate together. | [docs](../scripts/) |
| `scripts/caffeine.sh` | caffeine. While on: no auto-lock, no screen blanking (closing the lid still suspends, Super+Shift+L still locks). | [docs](../scripts/) |
| `scripts/camera.sh` | polybar camera indicator. The display agent sets the flag while any app has the webcam open; the bar shows a red camera then. | [docs](../scripts/) |
| `scripts/display-agent.py` | Camera in use: inotify on the webcam's device node (no polling); the flag file + a bar ping when it changes. | [docs](../scripts/) |
| `scripts/input-apply.sh` | apply touchpad / pointer / keyboard settings (at login, on i3 restart, and when Settings changes them) | [docs](../scripts/) |
| `scripts/keys.sh` | show every i3 keybind in a searchable rofi list (type to filter, Esc to close) | [docs](../scripts/) |
| `scripts/lag-now` | lag-now: press the key when the machine lags. It takes a one-second snapshot of what the machine is doing and what the kernel | [docs](../scripts/) |
| `scripts/login-apply.sh` | things that happen once per login (not on every i3 restart) | [docs](../scripts/) |
| `scripts/login-bg.sh` | wallpaper hooks: keeps the login screen's wallpaper equal to the desktop wallpaper (the greeter runs as another user | [docs](../scripts/) |
| `scripts/nightlight.sh` | night tint through the display's gamma ramp (no extra packages, no popups). | [docs](../scripts/) |
| `scripts/ocr.sh` | select an area on screen, put the text in it on the clipboard (needs tesseract + tesseract-data-eng) | [docs](../scripts/) |
| `scripts/osd.sh` | volume / mic / brightness actions. Silent: no bars, no popups (the bar shows the state). | [docs](../scripts/) |
| `scripts/pen-setup.sh` | pen-setup: map the ASUS stylus and touchscreen to the internal panel (run once at login by i3). | [docs](../scripts/) |
| `scripts/pin.sh` | pin the focused window (floating + sticky), or put it back | [docs](../scripts/) |
| `scripts/power-menu.py` | power menu (Super+Escape). One row of big tiles: Lock, Log out, Sleep, Hibernate, Restart, Shut down. | [docs](../scripts/) |
| `scripts/power-mode.sh` | performance mode for the power source I am on right now (saved, so it is also what plug/unplug restores) | [docs](../scripts/) |
| `scripts/power-watch.sh` | power-aware behaviour, event driven (upower). Re-applied on every plug/unplug. | [docs](../scripts/) |
| `scripts/rg-pre.sh` | ripgrep --pre helper for Spotlight's deep search: PDF text is extracted once and cached (by path + mtime) | [docs](../scripts/) |
| `scripts/rog-ui.sh` | client for the resident Spotlight/Settings process (it starts at login, so opening is near-instant). | [docs](../scripts/) |
| `scripts/rog-update.sh` | update the system the careful way: show the Arch news since my last update first, then (if I agree) run pacman -Syu. | [docs](../scripts/) |
| `scripts/scratch.sh` | scratch: my notepad. One persistent file (~/Documents/scratch.md) in a floating Neovim window that autosaves as I type, so there is | [docs](../scripts/) |
| `scripts/settings.py` | (title, value, subtitle) rows describing the battery right now. | [docs](../scripts/) |
| `scripts/shot.sh` | screenshot → clipboard (PNG, pastes into browsers/chat/editors) + ~/Pictures. Silent. | [docs](../scripts/) |
| `scripts/spotlight.py` | Resident mode: Spotlight is built once and shown on request (~instant); commands arrive on a FIFO. (Settings is NOT kept in memory.) | [docs](../scripts/) |
| `scripts/sync-server.sh` | manual backup of my research to hp-server (rsync over SSH). Runs only when I ask; never deletes anything there. | [docs](../scripts/) |
| `scripts/sysmon.sh` | open a GUI task monitor: per-process CPU/RAM/disk/GPU, per-app grouping | [docs](../scripts/) |
| `scripts/tablet.sh` | tablet mode = an on-screen keyboard (onboard) docked at the bottom that appears when a text field gets focus. | [docs](../scripts/) |
| `scripts/vaapi-check.sh` | is hardware video decoding available? Needs libva-utils (sudo pacman -S libva-utils). Read-only. | [docs](../scripts/) |
| `scripts/wallpaper-timer.sh` | (re)create the timer that changes the wallpaper every WALL_EVERY minutes (0 = never; set in Settings -> Wallpaper) | [docs](../scripts/) |
| `spotlight/aliases` | your own shortcuts for Spotlight:  name = what to open  (a folder, a file, a web address, or a command)\n# examples (remove the # to use):\n# thesis = | [docs](../spotlight/data-files.html) |
| `systemd/user/home-sarang-mnt-server.automount` | User units: sshfs mount of the home server | [docs](../i3/other-apps.html) |
| `systemd/user/home-sarang-mnt-server.mount` | User units: sshfs mount of the home server | [docs](../i3/other-apps.html) |
| `touchegg/touchegg.conf` | Touchpad gestures | [docs](../i3/other-apps.html) |
| `wallpaper-config/wallpaper-cycle-reverse.sh` | wallpaper-cycle-reverse: previous wallpaper (Super+Shift+Y). Same as wallpaper-cycle.sh but the index steps backwards. | [docs](../scripts/system.html#wallpaper-cyclesh) |
| `wallpaper-config/wallpaper-cycle.sh` | wallpaper-cycle: next wallpaper (Super+Y). The reverse script steps backwards. No root; needs feh. | [docs](../scripts/system.html#wallpaper-cyclesh) |
| `yazi/package.toml` | yazi config | [docs](../i3/other-apps.html) |
| `yazi/yazi.toml` | yazi config | [docs](../i3/other-apps.html) |


## spotlight (8 files)

| File | What it is | Documented |
|---|---|---|
| `.gitignore` | Ignores __pycache__ | [docs](../spotlight/install.html) |
| `README.md` | Spotlight for i3 | [docs](../spotlight/) |
| `alarm.py` | the window a Spotlight timer or reminder shows when it rings. Stays until I dismiss it (Enter / Esc); S snoozes 5 minutes. | [docs](../spotlight/timers.html) |
| `install.sh` | Installs Spotlight into ~/.config/scripts (existing copies are saved as *.old) and prints the i3 lines to add. | [docs](../spotlight/install.html) |
| `power-menu.py` | power menu (Super+Escape). One row of big tiles: Lock, Log out, Sleep, Hibernate, Restart, Shut down. | [docs](../spotlight/power-menu.html) |
| `rg-pre.sh` | ripgrep --pre helper for Spotlight's deep search: PDF text is extracted once and cached (by path + mtime) | [docs](../spotlight/deep-search.html) |
| `rog-ui.sh` | client for the resident Spotlight/Settings process (it starts at login, so opening is near-instant). | [docs](../scripts/system.html#rog-uish) |
| `spotlight.py` | Resident mode: Spotlight is built once and shown on request (~instant); commands arrive on a FIFO. (Settings is NOT kept in memory.) | [docs](../spotlight/internals.html) |


## nvim (25 files)

| File | What it is | Documented |
|---|---|---|
| `LICENSE` | MIT licence | [docs](../nvim/) |
| `README.md` | Neovim Keybindings & Settings | [docs](../nvim/) |
| `init.lua` | Bootstrap lazy.nvim | [docs](../nvim/install.html) |
| `lazy-lock.json` | Pinned plugin commits | [docs](../nvim/plugins.html) |
| `lua/plugins/alpha.lua` | alpha: the start screen (pixel cat header, six buttons: find file, new file, recent files, find text, config, quit). | [docs](../nvim/plugins.html) |
| `lua/plugins/autopairs.lua` | autopairs: auto-close brackets and quotes (nvim-autopairs, treesitter-aware) and auto-close/rename HTML/XML tags (nvim-ts-autotag). | [docs](../nvim/plugins.html) |
| `lua/plugins/catppuccin.lua` | catppuccin: the colour scheme (mocha flavour, transparent background) with integrations for cmp, gitsigns, neo-tree, treesitter, telescope and LSP. | [docs](../nvim/plugins.html) |
| `lua/plugins/completions.lua` | Autocomplete using luasnip | [docs](../nvim/plugins.html) |
| `lua/plugins/debugging.lua` | debugging: nvim-dap + nvim-dap-ui + nvim-dap-go. The UI opens on launch/attach and closes on exit; keymaps come from vim-options.lua (setup_dap_keymap | [docs](../nvim/plugins.html) |
| `lua/plugins/gitsigns.lua` | gitsigns: git signs in the gutter. NOTE: the hunk keymaps live in vim-options.lua (setup_gitsigns_keymaps) and are NOT attached here (no on_attach). | [docs](../nvim/plugins.html) |
| `lua/plugins/latex.lua` | -- lua/plugins/latex.lua | [docs](../nvim/plugins.html) |
| `lua/plugins/lsp-config.lua` | lsp-config: Mason + mason-lspconfig (14 servers) + nvim-lspconfig, using the Neovim 0.11 vim.lsp.config()/enable() API; diagnostics off in Markdown. | [docs](../nvim/plugins.html) |
| `lua/plugins/lualine.lua` | lualine: the status line (dracula theme; the catppuccin theme line is commented out). | [docs](../nvim/plugins.html) |
| `lua/plugins/luasnip.lua` | lua/plugins/luasnip.lua | [docs](../nvim/plugins.html) |
| `lua/plugins/neo-tree.lua` | neo-tree: the file explorer (30 columns wide). Keys: <leader>e toggles it, <leader>+ / <leader>- resize it (vim-options.lua). | [docs](../nvim/plugins.html) |
| `lua/plugins/none-ls.lua` | none-ls: formatters and linters as an LSP server (stylua, prettier, shfmt, black; markdownlint, yamllint), format on save, and <leader>gf. | [docs](../nvim/plugins.html) |
| `lua/plugins/render-markdown.lua` | lua/plugins/markdown-suite.lua | [docs](../nvim/plugins.html) |
| `lua/plugins/telescope.lua` | Telescope: fuzzy finder | [docs](../nvim/plugins.html) |
| `lua/plugins/telescope.lua.bak` | One lazy.nvim plugin spec | [docs](../nvim/plugins.html) |
| `lua/plugins/treesitter.lua` | Treesitter: Syntax highlighting | [docs](../nvim/plugins.html) |
| `lua/plugins/treesitter.lua.bak` | One lazy.nvim plugin spec | [docs](../nvim/plugins.html) |
| `lua/plugins/which-key.lua` | which-key: shows pending keybindings. <leader>? lists the buffer-local keymaps. | [docs](../nvim/plugins.html) |
| `lua/plugins.lua` | Empty leftover spec | [docs](../nvim/troubleshooting.html) |
| `lua/utils/snippets.lua` | lua/utils/snippets.lua | [docs](../nvim/snippets.html) |
| `lua/vim-options.lua` | Set line number | [docs](../nvim/keymaps.html) |


## HP desktop and server (109 files)

| File | What it is |
|---|---|
| ~/.config/hypr/conf/animations.lua | Short, snappy motion: springs for window movement, quint ease for the rest. |
| ~/.config/hypr/conf/autostart.lua | Session services. Each is launched once per compositor start (not on reload). |
| ~/.config/hypr/conf/binds.lua | · Super (Caps Lock is remapped to Super) is the main modifier, as in i3. |
| ~/.config/hypr/conf/colors.lua | Generated by ~/.config/hypr/theme/theme.sh — do not edit. Bare hex so callers can add alpha. |
| ~/.config/hypr/conf/eco.lua | Runtime state flags, stored as files under ~/.cache/hypr so they survive config reloads. |
| ~/.config/hypr/conf/env.lua | Environment, set before the compositor brings up clients. |
| ~/.config/hypr/conf/input.lua | Keyboard / pointer / touchpad. Hardware: AT keyboard, Synaptics TM2768 clickpad, |
| ~/.config/hypr/conf/look.lua | Look & feel. Tuned for a Haswell iGPU: 2-pass kawase blur, modest shadows, |
| ~/.config/hypr/conf/monitors.lua | Internal panel is 1600x900 → scale 1. Anything plugged in lands to the right |
| ~/.config/hypr/conf/palette.lua | Colours (Catppuccin-named roles). are bare hex so callers can add alpha: "rgba(" .. c.mauve .. "cc)" |
| ~/.config/hypr/conf/rules.lua | Window / layer / workspace rules. |
| ~/.config/hypr/conf/user.lua | Look presets chosen in the settings hub (scripts/settings.sh · Super+I). Stored as one file per key under |
| ~/.config/hypr/scripts/ambient.sh | Session timer (started by autostart): changes the wallpaper every N minutes when the settings hub's |
| ~/.config/hypr/scripts/caffeine.sh | caffeine.sh [toggle\|status] — hold a systemd idle inhibitor (hypridle respects it), |
| ~/.config/hypr/scripts/clipboard.sh | Clipboard history (cliphist) with image thumbnails. |
| ~/.config/hypr/scripts/colorpicker.sh | Pick a colour anywhere on screen; copies "#rrggbb" to the clipboard. |
| ~/.config/hypr/scripts/eco.sh | eco.sh toggle\|on\|off\|auto-on\|auto-off\|status |
| ~/.config/hypr/scripts/grayscale.sh | Grayscale the whole screen with a Hyprland screen shader |
| ~/.config/hypr/scripts/keybinds.sh | Cheat-sheet of every bind that has a description, straight from the running compositor. |
| ~/.config/hypr/scripts/kitty.sh | kitty launcher. On this Haswell iGPU Hyprland advertises no ARGB8888 dmabuf format, so kitty's |
| ~/.config/hypr/scripts/launcher.sh | launcher.sh spotlight\|drun\|calc\|emoji [extra rofi args] |
| ~/.config/hypr/scripts/lid.sh | lid.sh close\|open |
| ~/.config/hypr/scripts/look-toggle.sh | look-toggle.sh <key> <value>: flip one of the desktop-look presets (conf/user.lua) on and off from a key. |
| ~/.config/hypr/scripts/maintenance.sh | Maintenance mode: while you are working on the server, don't alert about the things you are knowingly breaking. |
| ~/.config/hypr/scripts/nightlight.sh | nightlight.sh [toggle\|status] |
| ~/.config/hypr/scripts/osd.sh | osd.sh vol up\|down\|mute · mic mute · bright up\|down |
| ~/.config/hypr/scripts/portals.sh | xdg-desktop-portal is socket/D-Bus activated at login, before Hyprland sets XDG_CURRENT_DESKTOP, so it |
| ~/.config/hypr/scripts/power-watch.sh | Enables eco mode when the charger is unplugged and disables it again on plug-in. |
| ~/.config/hypr/scripts/powermenu.sh | Power menu — port of ~/.config/rofi/powermenu.sh for Hyprland. |
| ~/.config/hypr/scripts/record.sh | record.sh full\|region\|status   — toggles a wf-recorder session. |
| ~/.config/hypr/scripts/reload.sh | Validate the config with the real parser first; only reload when it is clean, |
| ~/.config/hypr/scripts/remind.sh | Reminders that cost nothing while they wait: each one is a transient systemd user timer. |
| ~/.config/hypr/scripts/restart-shell.sh | Restart the shell pieces without touching your windows: bar, notifications, OSD, wallpaper. |
| ~/.config/hypr/scripts/rice | The rice and the server from any terminal, including over SSH (finds the running Hyprland session by itself). |
| ~/.config/hypr/scripts/rice-fix.sh | rice doctor: checks the rice and the server for known problems; --fix repairs the ones that are safe to repair. |
| ~/.config/hypr/scripts/rice-meter.py | What the rice itself costs (not your apps): RAM as PSS (shared pages split fairly) and CPU since the last |
| ~/.config/hypr/scripts/rice-snapshot.sh | Snapshots of the rice's own configuration (not your data): a compressed copy of the config directories it manages. |
| ~/.config/hypr/scripts/rice-update.sh | System update with a safety net and a readable aftermath. |
| ~/.config/hypr/scripts/screenshot.sh | screenshot.sh full\|region\|window\|annotate\|ocr\|qr   (ocr: text of a region → clipboard; qr: decode a code) |
| ~/.config/hypr/scripts/server-status.py | From the root jobs (rice-health): backup readability and drive health. |
| ~/.config/hypr/scripts/settings.sh | Settings hub (Super+I): appearance, desktop look, wallpaper, power and system in one rofi menu tree. |
| ~/.config/hypr/scripts/shell.sh | The desktop shell is swappable; the compositor, windows and theme don't change. |
| ~/.config/hypr/scripts/term.sh | Terminal launcher: foot server + footclient when foot is installed (one ~20 MB process for every window, |
| ~/.config/hypr/scripts/theme-init.sh | Apply GTK / icon / cursor / font settings through gsettings at session start |
| ~/.config/hypr/scripts/touchpad-toggle.sh | Enable/disable the touchpad (replaces ~/.config/i3/toggle-touchpad.sh). |
| ~/.config/hypr/scripts/tui.sh | tui.sh <command...> — run a TUI in a floating popup terminal (class tui-popup, see conf/rules.lua). |
| ~/.config/hypr/scripts/vnc.sh | Remote desktop over Tailscale only (wayvnc), started on demand so it costs nothing while off. |
| ~/.config/hypr/scripts/wallpaper.sh | wallpaper.sh init\|next\|prev\|random\|pick\|set <file>\|list |
| ~/.config/hypr/scripts/webapp.sh | Open a site in its own window, like an app. The list lives in webapps.conf, one "name\|url" per line. |
| ~/.config/hypr/scripts/window-switcher.sh | Window switcher. rofi's built-in `window` mode can't see Wayland toplevels, |
| ~/.config/hypr/scripts/zen.sh | Zen mode (Super+Z): no bar, no gaps/borders/rounding, notifications held back (do-not-disturb). |
| ~/.config/hypr/system/build-boot-theme.py | Approximate render of the menu, for checking the design without rebooting. |
| ~/.config/hypr/system/rice-health.py | None when the file is sound, otherwise why not. |
| ~/.config/hypr/system/server-tune.sh | Home-server fixes that need root. Restarts none of your services. |
| ~/.config/hypr/system/ssh-lan.sh | Only let SSH in from your home network, Tailscale and this machine, so the port is closed to the rest of the internet |
| ~/.config/hypr/system/sudo-window.sh | A time-limited passwordless sudo, for when you want an assistant (or yourself) to do root work without a prompt each time. |
| ~/.config/hypr/system/system-rice.sh | Boot-level rice: console font, Linux console colours from the first kernel message, a GRUB theme generated |
| ~/.config/hypr/theme/packs.py | Named theme packs (the real palettes of well-known schemes, mapped onto the Catppuccin role names every template uses). |
| ~/.config/hypr/theme/render.py | Most colourful of matugen's extracted source colours, weighted by how much of the image it covers. |
| ~/.config/hypr/theme/templates/btop.theme | (see the section for this folder) |
| ~/.config/hypr/theme/templates/fastfetch.jsonc | (see the section for this folder) |
| ~/.config/hypr/theme/templates/foot.ini | Generated by ~/.config/hypr/theme/theme.sh — edit theme/templates/foot.ini instead. |
| ~/.config/hypr/theme/templates/gtk-colors.css | Generated by ~/.config/hypr/theme/theme.sh — do not edit. |
| ~/.config/hypr/theme/templates/gtk-named.css | Generated by ~/.config/hypr/theme/theme.sh — adw-gtk3 / libadwaita named colours. |
| ~/.config/hypr/theme/templates/hypr-colors.lua | Generated by ~/.config/hypr/theme/theme.sh — do not edit. Bare hex so callers can add alpha. |
| ~/.config/hypr/theme/templates/hyprlock.conf | Generated by ~/.config/hypr/theme/theme.sh — do not edit. |
| ~/.config/hypr/theme/templates/kitty.conf | Generated by ~/.config/hypr/theme/theme.sh — do not edit. |
| ~/.config/hypr/theme/templates/qt-colors.conf | (see the section for this folder) |
| ~/.config/hypr/theme/templates/rofi-colors.rasi | Generated by ~/.config/hypr/theme/theme.sh — do not edit. |
| ~/.config/hypr/theme/templates/shell-colors.sh | Generated by ~/.config/hypr/theme/theme.sh — sourced by ~/.config/hypr/shell/rice.bash. Do not edit. |
| ~/.config/hypr/theme/templates/starship.toml | Generated by ~/.config/hypr/theme/theme.sh from the wallpaper palette — edit theme/templates/starship.toml instead. |
| ~/.config/hypr/theme/templates/vt-palette.sh | Generated by ~/.config/hypr/theme/theme.sh — Linux console (VT) palette, always from the dark palette. |
| ~/.config/hypr/theme/templates/waybar-ring.css | Generated by ~/.config/hypr/theme/theme.sh — workspace hue ring (Settings → Desktop look → Workspace colours). |
| ~/.config/hypr/theme/theme.sh | Wallpaper-driven theming. One palette -> Hyprland, waybar, swaync, swayosd, rofi, hyprlock, kitty, GTK, Qt, |
| ~/.config/hypr/shell/colors.sh | Generated by ~/.config/hypr/theme/theme.sh — sourced by ~/.config/hypr/shell/rice.bash. Do not edit. |
| ~/.config/hypr/shell/rice-completion.bash | (see the section for this folder) |
| ~/.config/hypr/shell/rice.bash | (see the section for this folder) |
| ~/.config/hypr/shell/vt-palette.sh | Generated by ~/.config/hypr/theme/theme.sh — Linux console (VT) palette, always from the dark palette. |
| ~/.config/hypr/shaders/crt.frag | version 300 es |
| ~/.config/hypr/shaders/deuteranopia.frag | version 300 es |
| ~/.config/hypr/shaders/eink.frag | version 300 es |
| ~/.config/hypr/shaders/grayscale.frag | version 300 es |
| ~/.config/hypr/shaders/invert.frag | version 300 es |
| ~/.config/hypr/shaders/paper.frag | version 300 es |
| ~/.config/hypr/shaders/protanopia.frag | version 300 es |
| ~/.config/hypr/shaders/redlight.frag | version 300 es |
| ~/.config/hypr/shaders/sepia.frag | version 300 es |
| ~/.config/hypr/shaders/tritanopia.frag | version 300 es |
| ~/.config/hypr/shaders/vignette.frag | version 300 es |
| ~/.config/hypr/hyprland.lua | ╭──────────────────────────────────────────────────────────────╮ |
| ~/.config/hypr/hypridle.conf | hypridle — dim → lock → screen off → suspend (on battery only) |
| ~/.config/hypr/hyprlock.conf | hyprlock — Catppuccin Mocha. Blurred live screenshot background, avatar from the old i3lock setup. |
| ~/.config/hypr/hyprlock-colors.conf | Generated by ~/.config/hypr/theme/theme.sh — do not edit. |
| ~/.config/hypr/hyprsunset.conf | hyprsunset — warm the screen after sunset. Super+F3 forces warm until toggled again. |
| ~/.config/hypr/server.conf | What counts as "the server": scripts/server-status.py checks these. One per line: a system unit, "user:" for a |
| ~/.config/hypr/webapps.conf | name\|url   (Super+Alt+B picks one; webapp.sh <name> opens it) |
| ~/.config/hypr/README.md | Hyprland setup — HP EliteBook 840 G1 · Catppuccin Mocha |
| ~/.config/hypr/doctor.sh | Checks that everything the Hyprland setup relies on is present, and validates the config. |
| ~/.config/hypr/install.sh | Installs everything in packages.txt. Run it yourself (needs sudo):  ~/.config/hypr/install.sh |
| ~/.config/hypr/report.sh | report.sh — collect everything needed to debug a first run into one file you can paste/share. |
| ~/.config/hypr/packages.txt | Packages for the Hyprland setup (all in the official repos — no AUR needed). |
| ~/.local/share/hp-dash/README.md | see the hp-dash page |
| ~/.local/share/hp-dash/hp-dash.service | The web terminal's tmux session lives in this unit's cgroup: only stop the main process on a restart, so restarting the |
| ~/.local/share/hp-dash/server.py | peer -> host -> (caller checks session). Returns False after having answered. |
| ~/.local/share/hp-dash/static/app.css | see the hp-dash page |
| ~/.local/share/hp-dash/static/app.js | see the hp-dash page |
| ~/.local/share/hp-dash/static/favicon.svg | see the hp-dash page |
| ~/.local/share/hp-dash/static/index.html | see the hp-dash page |
| ~/.local/share/hp-dash/static/vendor/* | xterm.js, noVNC and the JetBrains Mono Nerd Font (third-party, vendored) |
