# i3-dotfiles

My desktop, lovingly over-engineered. This is the i3 setup I live in on an **ASUS ROG Flow X13** (Ryzen 9 7940HS, RTX 4050, Arch Linux, X11): warm amber and chalk colours, vim-style keys, and not a single notification. If something on my screen makes a noise, it's because I asked it to.

It started as "I'll just tidy the config a bit" and then I kept going. You have been warned.

## What it looks like
![A short screen recording: Spotlight finds apps, does maths, shows emoji, previews files, then the layout flips between tabbed and stacked](docs/img/demo.gif)
*About a minute of me poking at everything. Spotlight first, then the i3 layouts and the Settings app.*

Every shot here was taken on a throwaway virtual screen running the same configs, so none of my real windows (or my Wi-Fi name) sneak into the pictures.

![My desktop: Neovim on the left, fastfetch and a git log tiled on the right, bar along the bottom](docs/img/desktop.png)
*The everyday layout: tiled, keyboard-driven, and the bar stays out of the way at the bottom.*

| Tabbed (`Super+W`) | Stacked (`Super+S`) |
|---|---|
| ![Two terminals as tabs in one tile](docs/img/tabbed.png) | ![Two terminals stacked with title bars](docs/img/stacking.png) |

| My Settings app | The power menu (`Super+Escape`) |
|---|---|
| ![Settings opens tiled like any other window](docs/img/settings.png) | ![Lock, log out, sleep, hibernate, restart, shut down as a row of tiles](docs/img/power.png) |
| One window for display, power, input, sound, wallpaper, the bar and backups. It opens tiled like everything else. | Destructive buttons need a second Enter, so I cannot nuke my session by accident. |

![The lock screen: blurred wallpaper, big thin clock, a round ring with my name](docs/img/lock.png)
*The lock screen. Blurred wallpaper, a big thin clock, a round ring with my name on it.*

![Spotlight on the desktop, searching for settings](docs/img/spotlight.png)
*My Spotlight on top of all that. Its own repo has the full tour: [sarang-kernel/spotlight](https://github.com/sarang-kernel/spotlight).*

## Documentation
The full, detailed docs live on a small site: **[https://sarang-kernel.github.io/i3-dotfiles/](https://sarang-kernel.github.io/i3-dotfiles/)**. One section per thing I built: the [i3 desktop](https://sarang-kernel.github.io/i3-dotfiles/i3/), [Spotlight](https://sarang-kernel.github.io/i3-dotfiles/spotlight/), every [script](https://sarang-kernel.github.io/i3-dotfiles/scripts/), [rog-tune](https://sarang-kernel.github.io/i3-dotfiles/rog-tune/), the [restore ISO](https://sarang-kernel.github.io/i3-dotfiles/iso/), [Neovim](https://sarang-kernel.github.io/i3-dotfiles/nvim/) and the [HP home server](https://sarang-kernel.github.io/i3-dotfiles/hp/), plus a [log of what I changed and why](https://sarang-kernel.github.io/i3-dotfiles/changes/).
The reference tables (keybindings, settings, parts, dependencies, a file index) are generated from the real files, so they cannot drift. The source is in `docs/`.

## What's in here
| Folder | What it is |
|---|---|
| `i3`, `polybar`, `picom`, `kitty`, `rofi`, `mpv`, `btop`, `yazi`, ... | the desktop itself: window manager, bar, compositor, terminal and friends |
| `scripts/` | the glue that holds my days together: my own **Spotlight** (apps, files, maths, clipboard history and actions in one search box), a GTK4/libadwaita **Settings** app, power modes, adaptive refresh rate, night tint, screen rotation, backups to my home server, and `rog-update.sh`, which makes me read the Arch news before it lets me update (and can roll back when I regret it) |
| `apps/spotlight/` | a copy of my standalone Spotlight repo (launcher, power menu, installer). The live copies sit in `scripts/` |
| `i3lock/lock.sh` | my lock screen: blurred wallpaper, plus a big thin clock and a round ring with my name on it if `i3lock-color` is installed (plain `i3lock` if not) |
| `rog-tune/` | the root-side tuning. `rog-tune.sh` is a dry run unless I say `--apply` (and `--undo` exists for moments of doubt); `rog-lean-session.sh` is the user-level installer, and `rog-snappy.sh` makes the CPU quicker to ramp on the charger (balance_performance instead of balance_power). Highlights: the **greetd + ReGreet** login screen (warm theme, rotates with the accelerometer), a restore point before every pacman transaction, power saving on battery, kernel and GRUB options |
| `docs/make-screenshots/` | how I take the pictures above on a throwaway virtual screen, so none of my real windows end up in them |
| `iso/` | the recipe for my restore ISO: a bootable Arch installer that rebuilds this laptop offline, with `rog-restore` as the installer. The ISO itself is too big for GitHub; see `iso/README.md` |
| `rog/settings.env` | every setting my scripts read. The Settings app writes it, so I rarely touch it by hand |

## Installing it (on a laptop that isn't mine: good luck and godspeed)
```
./install.sh                          # copies my user config, backing up whatever it replaces
sudo ./rog-tune/rog-tune.sh           # dry run: shows every root change as a diff
sudo ./rog-tune/rog-tune.sh --apply greetd speed tidy   # an example
```
What I install first (Arch): `i3-wm polybar picom kitty rofi python-gobject gtk4 libadwaita libqalculate plocate ripgrep xss-lock xclip imagemagick`. Optional extras: `i3lock-color` (AUR) for the pretty lock screen, and `greetd greetd-regreet sway` for the login screen.

## Fair warning
The monitor name, touchpad id, PCI addresses and GRUB entries in `rog-tune.sh` are all for *my* laptop. Please read the dry run before applying anything; I'd hate to be the reason your boot breaks.

My Neovim config lives in its own repo.
