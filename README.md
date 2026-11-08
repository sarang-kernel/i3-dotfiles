# i3-dotfiles

Warm amber / chalk i3 setup for an **ASUS ROG Flow X13** (Ryzen 9 7940HS, RTX 4050) on **Arch Linux + X11**. Vim-style keys, no notifications, no on-screen clutter.

| Folder | What |
|---|---|
| `i3`, `polybar`, `picom`, `kitty`, `rofi`, `btop`, `mpv`, `yazi`, ... | desktop config |
| `scripts/` | the glue: resident GTK3 **Spotlight** (apps, files, calculator, clipboard history, actions), GTK4/libadwaita **Settings**, power modes, adaptive refresh rate, night tint, rotation, backups to a home server, `rog-update.sh` with rollback |
| `apps/spotlight/` | a copy of the standalone Spotlight repo (launcher + power menu + installer); `scripts/` holds the live copies |
| `i3lock/lock.sh` | lock screen: blurred wallpaper; clock + accent ring if `i3lock-color` is installed, plain `i3lock` otherwise |
| `rog-tune/` | root-side tuning (`rog-tune.sh`: dry run by default, `--apply`, `--undo`) and the user-level installer `rog-lean-session.sh`. Parts include the **greetd + ReGreet** login screen (warm theme, rotates with the accelerometer via sway), restore points before every pacman transaction, power saving on battery, kernel/GRUB options |
| `rog/settings.env` | the settings the scripts read (Settings app writes it) |

## Install
```
./install.sh                          # copies the user config, backing up what it replaces
sudo ./rog-tune/rog-tune.sh           # dry run: shows every root change as a diff
sudo ./rog-tune/rog-tune.sh --apply greetd speed tidy   # example
```
Needs (Arch): `i3-wm polybar picom kitty rofi python-gobject gtk4 libadwaita libqalculate plocate ripgrep xss-lock xclip imagemagick`; optional `i3lock-color` (AUR), `greetd greetd-regreet sway`.

Machine-specific: monitor name/modes, touchpad id, the PCI addresses and GRUB entries assumed in `rog-tune.sh` are for this laptop. Read the dry run before applying anything.
`nvim` lives in its own repo.
