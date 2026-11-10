"""Hand-written pages of the i3 section."""
from common import *

P = "i3 desktop"


def build():
    write("i3/index.md", fm(P, None, 2, children=True, desc="My i3 desktop on the ASUS ROG Flow X13"), """# My i3 desktop

This is the desktop I live in on an **ASUS ROG Flow X13** (Ryzen 9 7940HS, RTX 4050, Arch Linux, X11): the i3 window manager, a bottom polybar, picom for translucency, kitty, my own Spotlight and Settings apps, and a pile of small scripts that make the laptop behave (power modes, refresh rate, rotation, lock screen).
Everything is in one repository: [`sarang-kernel/i3-dotfiles`](https://github.com/sarang-kernel/i3-dotfiles).

![The everyday layout](../img/desktop.png)

## How the pieces fit together

```text
 login (greetd + ReGreet)              rog-tune/  (root side, dry-run by default)
        |                                    |
        v                                    v
   startx -> i3  --exec-->  picom, polybar, wallpaper, power-watch.sh, display-agent.py,
        |                    nightlight.sh daemon, autorotate.sh, autocaffeine.sh,
        |                    rog-ui.sh start  ->  resident Spotlight process
        |
        +-- keys (Super+D, Super+comma ...) -> Spotlight / Settings / scripts
        +-- ~/.config/rog/settings.env  <-- written by the Settings app, read by every script
```

- **i3** is the window manager; the config is a standard i3 v4 file with my additions, each tagged `# rog-tune:` so I can find them.
- **`settings.env`** is the glue. The Settings app writes it; scripts *source* it. No daemon keeps state in memory.
- **Spotlight and Settings** are my own GTK programs. Spotlight is a resident process (so it opens instantly), Settings starts on demand.
- **rog-tune** is how all of this got installed and how the root-side parts are applied. Everything has a dry run and an undo.

## What's in this section

| Page | What you get |
|---|---|
| [Install and layout](install.html) | Packages, `install.sh`, what each folder of the repo is |
| [Keybindings](keybindings.html) | Every binding, generated from the config |
| [Windows, workspaces and rules](windows.html) | Window rules, borders, colours, layout cheat-sheet |
| [Autostart and session](autostart.html) | Everything i3 starts, and why |
| [Polybar](polybar.html) | The bar: modules, clicks, helper scripts |
| [Compositor (picom)](compositor.html) | Translucency, blur, the AC/battery variants |
| [Terminal (kitty)](terminal.html) | Font, opacity, vim-style scrollback |
| [Lock screen](lock-screen.html) | The i3lock-color lock screen and the idle timer |
| [Colours, accent and fonts](theme.html) | The warm palette and how the accent colour is applied |
| [Other app configs](other-apps.html) | btop, mpv, cava, dunst, touchegg, yazi, rofi, GTK ... |
| [How the screenshots are made](screenshots.html) | The virtual-screen trick behind the README pictures |
| [Troubleshooting](troubleshooting.html) | Things that went wrong and what fixed them |
""")

    write("i3/install.md", fm("Install and layout", P, 1), """# Install and layout

{TOC}

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
""".replace("{TOC}", TOC))

    write("i3/polybar.md", fm("Polybar", P, 6), """# Polybar

{TOC}

## The bar

One bar, `toph` (the name is a leftover; it sits at the **bottom**: `bottom = true`), full width, `18pt` high with 5pt borders in the same translucent black (`#d9000000`), `pseudo-transparency = true` so it blends with the compositor.
The monitor comes from the `MONITOR` environment variable (empty means the primary one). i3 starts it with
`killall -q polybar; … exec polybar -c ~/.config/polybar/config.ini toph` on every start and reload, so there is never more than one bar.
`enable-ipc = true` lets `polybar-msg` control it (`Super+B` toggles it with `polybar-msg cmd toggle`; the accent script restarts it with `polybar-msg cmd restart`; the lock screen hides it while locked).

Fonts: `font-0` MesloLGS Nerd Font Mono 14 (glyphs), `font-1` JetBrains Mono light 12 (the numbers and text; weight and size are set in Settings → Top Bar).

Layout: **left** `xworkspaces xwindow`, **centre** `date`, **right** `pulseaudio brightness battery memory cpu network mic camera`. The right side is editable from the Settings app: each module is a switch (Settings → Top Bar → *Shown in the bar*), which rewrites the `modules-right` line.

## Modules

| Module | Type | What it shows / does |
|---|---|---|
| `xworkspaces` | internal/xworkspaces | The ten workspaces. Active one has a filled box (or a thin underline; Settings → Top Bar → *Active workspace marker*), occupied ones are plain, empty ones are dimmed, urgent ones turn red |
| `xwindow` | internal/xwindow | Title of the focused window, cut at 60 characters |
| `date` | internal/date | `Mon 10 Nov  13:00`, updates every 5 s; `date-alt` is the full ISO date with seconds |
| `pulseaudio` | internal/pulseaudio | Volume percentage with an icon, or *muted* |
| `brightness` | custom/script | `bri-follow.sh`: reads the backlight from sysfs and waits on a private fifo (no polling process). Click = 100 %, scroll = ±1 % (`osd.sh bri up1/down1`) |
| `battery` | internal/battery | `BAT0` on `AC0`: charging animation, discharge ramp, `Full`; polls every 5 s |
| `memory` | internal/memory | Used memory percentage every 5 s; click opens the task monitor (`sysmon.sh`) |
| `cpu` | internal/cpu | CPU percentage every 5 s; click opens the task monitor |
| `network` | custom/script | `iwd-status.sh`: asks `iwctl station wlan0 show` and prints the SSID or *Disconnected* every 5 s |
| `mic` | custom/script | `mic-follow.sh`: event driven through `pactl subscribe`; grey *live* or red *muted*; click toggles mute |
| `camera` | custom/ipc | `camera.sh bar`: a red camera while any program has the webcam open (the display agent pings it) |
| `systray`, `filesystem`, `xkeyboard` | defined, not used | Kept in the file in case I want them back |

The old `wlan`/`eth` modules are commented out ("to avoid errors") in favour of the single `network` script, because the machine uses `iwd` and not NetworkManager.

## Helper scripts (`polybar/scripts`)

- **`bri-follow.sh`** reads `max_brightness` once, then loops: print the percentage when it changed, then `read -t 0.4` on a fifo. Zero extra processes.
- **`mic-follow.sh`** prints the state, then reads lines from a `pactl subscribe` fifo and re-prints on any `source` or `server` event. Its traps kill the `pactl` child so a polybar restart leaves nothing behind.
- **`iwd-status.sh`** calls `iwctl` twice per interval; simple on purpose. The interface name `wlan0` is hard-coded.

## Colours and the accent

The `[colors]` table is my warm palette (`base #1c1917`, `text #e7dfd3`, `mauve #e0a458` is the accent …); see [Colours, accent and fonts](theme.html). The accent script edits the `mauve = …` line, so the active workspace follows the accent setting.

## Things that bite

- The `network` module shows your **Wi-Fi name** in the bar, so I leave it out of screenshots (see [How the screenshots are made](screenshots.html)).
- A polybar restart is cheap, but anything that restarts it on a timer would flicker; nothing does.
""".replace("{TOC}", TOC))

    write("i3/compositor.md", fm("Compositor (picom)", P, 7), """# Compositor (picom)

{TOC}

I run picom so terminals, polybar, Spotlight and notifications can be **translucent with the blurred wallpaper behind them**. Opaque windows are never blurred, shadows and fades are off, and the corner radius is zero except for Spotlight's rounded box.

## Two variants and a symlink

`~/.config/picom/picom.conf` is **not a file**: it is a symlink to one of two real files, and `power-watch.sh` repoints it whenever the power source or the performance mode changes, then sends picom `SIGUSR1` so it reloads:

| File | Used when | What is different |
|---|---|---|
| `picom-ac.conf` | On AC power and the mode is not Quiet | `blur-background = true` with `dual_kawase` strength 6 (everything except the desktop is blurred), `inactive-dim` available |
| `picom-bat.conf` | On battery, or in Quiet mode | **No blur** and no dimming, the GPU stays near idle. One exception: a blur rule that matches *only* Spotlight so its text stays readable while it is open |

Both files share: `backend = "glx"`, `vsync = true`, `use-damage = true` (redraw only what changed), `unredir-if-possible = false`, `shadow = false`, `fading = false`, `corner-radius = 0` with `corner-radius-rules = [ "26:class_g = 'Spotlight'" ]`, `detect-client-opacity = true`, `mark-wmwin-focused`, `mark-ovredir-focused`.
`picom-ac.conf` additionally has `inactive-dim-fixed = true` and `focus-exclude` for Rofi and Polybar.

{% raw %}**Careful when editing:** `sed -i` on a symlink replaces it with a plain file, which silently breaks the AC/battery switch until the next plug event relinks it. Edit `picom-ac.conf` and `picom-bat.conf` themselves.{% endraw %}

## What the Settings app changes

Settings → Display → *Effects*: **Blur on AC power** rewrites `blur-background = true|false;` in `picom-ac.conf`, and **Dim inactive windows** rewrites `inactive-dim = 0.10` or `0.0`. After editing it sends picom `SIGUSR1`. Settings never edits the battery variant.

## Why `unredir-if-possible = false`

picom can "unredirect" a fullscreen window: it stops compositing and lets the window go straight to the screen, which saves power for video. The lock screen is a fullscreen window, and I saw it fail to appear after the idle timeout (the old screen stayed up and the lock only showed after I touched the mouse).
I tested that path 12 times in a row with and without unredirect and it painted every time either way, so I cannot prove the setting is *the* fix; I keep it off because it removes one path that is known to leave stale frames. The cost is a little more power while a video is fullscreen.
Two things I tried and **removed**:

- `use-damage = false` made the lock screen reliable too, but turns every change into a full-screen redraw and blur at 2560×1600, and I suspected it of adding lag.
- Sending picom `SIGUSR1` from `lock.sh` to force a repaint **made things worse**: in an A/B run of 8 lock activations it failed to paint 3 times with the poke and 0 times without it.

## Reload, restart, debug

```bash
pkill -USR1 -x picom                        # reload the config (what the scripts do)
picom --config ~/.config/picom/picom.conf   # run it in a terminal to see errors
pgrep -x picom || echo "not running"        # i3 starts it with a plain exec: if it dies it stays dead
```

i3 starts picom with a plain `exec`, so a crash is not restarted. If translucency disappears, run it again as above.

## Performance notes

I measured the compositor with a GL test (`glxgears`) at 90 Hz and it held 90.0 fps; the blur only costs real GPU time while windows change. On battery the no-blur variant keeps the GPU idle.
""".replace("{TOC}", TOC))

    write("i3/terminal.md", fm("Terminal (kitty)", P, 8), """# Terminal (kitty)

{TOC}

kitty is my terminal (`Super+T`; `Super+Enter` runs whatever `i3-sensible-terminal` picks). The config is two files: `kitty.conf` and `theme.conf` (included by the first).

## `kitty.conf`

| Setting | Value | Why |
|---|---|---|
| `font_family` | JetBrainsMono Nerd Font | Icons for neo-tree, lualine, the prompt |
| `font_size` | 13.0 | The panel is 2560×1600 at a high DPI |
| `window_padding_width` | 8 | |
| `repaint_delay`, `input_delay` | 6, 1 | Lower input latency (added by the `kitty` part of `rog-lean-session.sh`) |
| `enable_audio_bell` | no | |

## Vim-style scrollback

`ctrl+shift+space` opens the scrollback in kitty's pager and the pager has vim-like keys:

- Motion: `h j k l`, `0`, `^`, `$`, `w`, `e`, `b`, `ge`; paging `ctrl+u/d/b/f`; `gg` / `G`.
- Search: `/`, `?`, `n`, `N`.
- Selection: `v` (characters), `V` (lines), `ctrl+v` (block); `y` yanks; `esc` leaves.

Kitty may print *Shortcut: scrollback_pager has unknown key, ignoring*: these `map scrollback_pager …` lines use a syntax that kitty versions ignore with a warning. It is harmless but it is why you may see that line when running kitty from a terminal or a script.

## `theme.conf`: warm black, translucent

`background #000000` with `background_opacity 0.66`, `dynamic_background_opacity yes`: with picom running, the blurred wallpaper shows through. Foreground `#E7DFD3`, selection background `#E0A458` (the accent), cursor `#E0A458`, URL colour `#E5C07B`, and a 16-colour palette in the same warm tones (`color1 #EA6962`, `color2 #A9B665`, `color3 #D8A657`, `color4 #7DAEA3`, `color5 #D3869B`, `color6 #89B482`).
The comment in the file lists the opacity keys: `ctrl+shift+a` then `m` / `l` = more / less opaque, `a` then `1` = fully opaque, `a` then `d` = back to the default.

The Settings app has an **Opacity** slider (Windows & Terminal → Terminal): it rewrites `background_opacity` and sends kitty `SIGUSR1`, which makes kitty reload its config so open terminals change immediately.

## Window classes I use

`kitty --class scratch` (the notepad), `--class rog-sync` (floating update/backup windows: 1100×640 centred, `for_window` rule), `--class sysmon` (btop fallback).
""".replace("{TOC}", TOC))

    write("i3/lock-screen.md", fm("Lock screen", P, 9), """# Lock screen

{TOC}

## What you see

A blurred, darkened copy of the current wallpaper, the date and a large thin clock near the top, and a round ring with my name at the bottom. With plain `i3lock` (no `-color` fork) it falls back to the simple lock.

## How it is started

| Trigger | How |
|---|---|
| `Super+Shift+L` | i3 runs `~/.config/i3lock/lock.sh` directly |
| Power menu, Spotlight ("lock") | the same script |
| **Idle timeout** | `xss-lock --transfer-sleep-lock -- lock.sh` (started by i3) runs it when the X screensaver timer fires. The timer length comes from `power-watch.sh` (`xset s`): 10 min on AC, 2 min on battery |
| Suspend / hibernate | `--transfer-sleep-lock` makes xss-lock take a logind inhibitor, so the screen locks *before* the machine sleeps |
| Caffeine on | The timers are switched off (`xset s off`), so the idle path never fires; the manual shortcut still works |

## `lock.sh` step by step

1. If the bar is visible it is hidden (`polybar-msg cmd hide`) and a trap shows it again on any exit, so the bar never sits on top of the lock.
2. The background is `~/.cache/lock-bg.png`, made by `login-bg.sh` whenever the wallpaper changes (i3lock only reads PNG).
3. Common options: `--nofork --ignore-empty-password --show-failed-attempts -c 14110f`.
4. If `i3lock --version` mentions *Raymond Li* (i3lock-color) it adds the rich options: a `%H:%M` clock at 150 pt (Noto Sans Light) and a date line, a ring of radius 54 with the user's name below it (the real name from `/etc/passwd`, capitalised), fixed translucent-white ring colours, and `Incorrect password` in a warm orange on failure. `--pass-media-keys --pass-volume-keys` keep the volume keys working.
5. If the rich invocation exits within two seconds with an error (an option this build does not know) it falls back to a plain `i3lock` with the common options.

`i3lock/avatar/avatar.jpg` and `.eps` are leftovers from an earlier lock screen; the current script does not use them.

## The lock screen that did not show

The idle path once failed to repaint: the old screen stayed up after the timeout and the lock only appeared after I moved the mouse. The fix history is on the [Compositor page](compositor.html#why-unredir-if-possible--false) and in [Changes](../changes/).

## Testing the timeout path without waiting ten minutes

```bash
xset s activate        # fires the same xss-lock path as an idle timeout
pkill -x i3lock        # unlock it again from another machine over ssh if you must
```

(`xset s activate` locks *your real session*; do not do it on a machine you cannot reach another way.)

## Related

[Power and display scripts](../scripts/power-display.html) set the timers; [Settings → Power & Performance](../scripts/settings-app.html) changes them; the **login** screen is a different program (greetd + ReGreet, configured by `rog-tune`'s `greetd` part).
""".replace("{TOC}", TOC))

    write("i3/theme.md", fm("Colours, accent and fonts", P, 10), """# Colours, accent and fonts

{TOC}

## The palette

A warm dark palette instead of the usual cool Catppuccin blues. It is defined once in `polybar/config.ini` (`[colors]`) and echoed in i3 and kitty.

| Name | Hex | Used for |
|---|---|---|
| `base` | `#1c1917` | Background |
| `mantle` | `#14110f` | Darker background (unfocused window border background) |
| `crust` | `#0f0d0c` | Darkest (text on the active workspace box) |
| `text` | `#e7dfd3` | Foreground |
| `subtext0` / `subtext1` | `#b5aa9a` / `#cfc5b5` | Dimmer text, disabled items |
| `surface0` / `1` / `2` | `#2b2622` / `#3a342e` / `#4a4239` | Borders and panels |
| `overlay0` / `1` / `2` | `#6e655a` / `#857b6e` / `#9b9084` | Muted text |
| `mauve` | `#e0a458` | **The accent** (active workspace, focused border) |
| `red`, `maroon`, `peach`, `yellow`, `green`, `teal`, `blue`, `lavender`, `sapphire`, `sky`, `pink`, `flamingo`, `rosewater` | `#e06c5a` `#c8786a` `#e39a5f` `#e5c07b` `#a3a27a` `#b8a58a` `#d4a373` `#e0b88a` `#c99a6b` `#d9b48f` `#d98c7a` `#e6b3a1` `#f0d9c8` | Warm variants of the usual names |

## The accent colour

The accent is **one setting, applied in three places**:

1. **Spotlight, Settings, the power menu and the alarm window** read `ACCENT_MODE` / `ACCENT_HEX` themselves and re-style their CSS.
2. **Polybar's active workspace** (`mauve = …`) and
3. **the focused window's border** (`client.focused`) are edited by `accent.sh`.

(`lock.sh` reads `ACCENT_HEX` into a variable but its current options use fixed translucent-white colours, so the lock screen does not follow the accent.)

Modes (Settings → General → *Accent colour*): **Amber** (`#e0a458`, the default), **From the wallpaper** (`accent.sh wallpaper` picks the most saturated mid-lightness colour of the current wallpaper), **Custom** (the colour chooser; picking a colour switches the mode to Custom). *Theme* (light / dark / follow the night schedule) is `APPEARANCE`.

## Fonts

| Where | Font |
|---|---|
| i3 title font (rarely visible: no title bars) | Meslo LGM Nerd Font 11 |
| Polybar glyphs / text | MesloLGS Nerd Font Mono 14 / JetBrains Mono light 12 |
| kitty | JetBrainsMono Nerd Font 13 |
| GTK apps | Noto Sans 11 |
| Lock screen | Noto Sans Light (clock), Noto Sans Medium (date, name) |

## GTK, icons, cursor

`gtk-3.0/settings.ini` and `gtk-4.0/settings.ini` are identical: dark theme preferred, **Papirus-Dark** icons, Adwaita cursor at 32 px, animations off, cursor blink off. (GTK animations off is deliberate: fewer frames to draw.)

## Wallpapers

`~/Pictures/wallpapers/day` and `/night`; `Super+Y` / `Super+Shift+Y` step forward and back, Settings → Wallpaper sets the day/night switch hours and an automatic change interval. The current wallpaper's path is in `~/.cache/current_wallpaper`; changing it also refreshes the lock screen image, the login screen wallpaper and (in *From the wallpaper* mode) the accent.
""".replace("{TOC}", TOC))

    write("i3/other-apps.md", fm("Other app configs", P, 11), """# Other app configs

{TOC}

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
""".replace("{TOC}", TOC))

    write("i3/screenshots.md", fm("How the screenshots are made", P, 12), """# How the screenshots are made

The pictures in the READMEs were taken on a **throwaway virtual screen**, not on my real desktop, so none of my real windows (or my Wi-Fi name in the bar) end up in them. The tooling is in `docs/make-screenshots/` of the repo.

## The idea

`Xvfb :99` is an invisible X server. A second copy of my configs runs inside it: the real i3 config with every autostart line stripped (so nothing touches the real session), a polybar config without the Wi-Fi module, and a separate Spotlight process with its own runtime and state directories (so my real clipboard history is not read or written). `xdotool` types into it and `import` or `ffmpeg x11grab` captures it.

## The steps

| Script | What it does |
|---|---|
| `prep.sh` | Builds the three throwaway configs (`i3.conf`, `polybar.ini`) under `~/shots/vx` and copies the scripts there |
| `start.sh` | Starts Xvfb at 2560×1600 with a private `XDG_RUNTIME_DIR` and `XDG_STATE_HOME`, then runs i3 and Spotlight inside a private D-Bus session (`inner.sh`) |
| `scene.sh` | Opens kitty windows (Neovim, fastfetch, a git log), then drives Spotlight with `xdotool` through apps, maths, units, emoji, timers, clipboard, files, preview, actions, commands, windows and all-apps; then the power menu, the Settings app tiled in, tabbed and stacked layouts and the lock screen. Writes `out/*.png` |
| `demo.sh` | Records the same session to `demo.mp4` and converts it to a small GIF |

Requirements: `xorg-server-xvfb`, `xdotool`, `ffmpeg`, `imagemagick`, `kitty`, `fastfetch`.

## Lessons (so I do not relearn them)

- **No compositor in the virtual screen.** With picom running under software GL, terminal windows came out blank, so Spotlight looks solid dark in the pictures. The real thing is translucent.
- **It is slow** (software rendering). `scene.sh` takes about seven minutes; short waits give half-drawn frames, so the script waits generously after each keystroke burst.
- **Never screenshot the real screen for a public repo.** The first attempt did, and caught private windows. Every picture is looked at before it is committed.
- **Escape twice** after each scenario: Spotlight's preview and all-apps modes eat the first Escape, and a leftover open Spotlight swallows the next scenario's typing.
""")

    write("i3/troubleshooting.md", fm("Troubleshooting", P, 13), """# Troubleshooting

{TOC}

Everything here happened to me at least once.

## Super key does nothing / Caps Lock is Super

The config uses `Mod4` as `$mod`. On my laptop Caps Lock is remapped to Super in three places: Xorg's `/etc/X11/xorg.conf.d/00-keyboard.conf` (`XkbOptions "caps:super"`, written by `localectl`), `~/.xprofile` (`setxkbmap -option caps:super`), and the greeter's sway config (`xkb_options caps:super`) so the login screen behaves the same. The old `setxkbmap` lines in `i3/config` are commented out. If Super stops working after a keyboard change, run `setxkbmap -option caps:super` and check with `xev`.

## A script says it is "already running" or two copies run

Every long-running script kills its previous copy through a pid file under `$XDG_RUNTIME_DIR` on start. If a copy survives an i3 restart, check with `pgrep -af 'display-agent|power-watch|nightlight|autocaffeine|autorotate'` and kill the extras; the next reload fixes it.

## The screen did not rotate / rotated wrongly

`autorotate.sh` needs the sensor claim from `iio-sensor-proxy`. If `monitor-sensor` prints *Failed to claim*, the script retries with backoff (2 s doubling to 30 s); `logger -t autorotate` entries in the journal show it. `Super+Shift+O` may have **frozen** rotation: check `~/.local/state/autorotate.lock`. The panel name is `eDP-1` or `eDP-2` depending on which GPU driver registered first; everything looks it up at run time (except `rog-lean-session.sh`'s optional `hz60` part, which hard-codes `eDP-1`).

## The refresh rate "blinks"

Adaptive refresh switches the mode after 60 s of idleness and back on the first key; switching a mode blinks the panel. It only acts from 110 Hz upward, so at 90 Hz on AC it does nothing. If you see blinking, check `ADAPTIVE` and `RATE_AC` in [Settings](../scripts/settings-reference.html). `Settings → Display → Adaptive refresh` turns it off.

## Screen does not lock after the timeout (or locks only when I move the mouse)

See [Lock screen](lock-screen.html) and [Compositor](compositor.html). Quick checks: `xset q | grep -A3 "Screen Saver"` (timeout), `pgrep -a xss-lock`, `pgrep -x picom`.

## No translucency / terminals fully black

picom is not running (`pgrep -x picom`), or `picom.conf` was replaced by a regular file. Fix: `ln -sfn picom-ac.conf ~/.config/picom/picom.conf; pkill -USR1 -x picom` or start picom again.

## Spotlight does not open

`rog-ui.sh restart`, then press `Super+D`. If it still fails, run `python3 ~/.config/scripts/spotlight.py` in a terminal to see the traceback. Spotlight must be started from the desktop session, not over ssh (it hands its environment to everything it launches).

## gedit crashes or hangs on close

gedit 51 segfaults in `libgedit-51.so` on this machine (reproducible with `gedit --standalone`) and spins a CPU core for several seconds on a normal launch. I replaced my quick-notes use with the Neovim scratchpad (`Super+N`).

## The clock is wrong in the bar

The bar shows local time through `internal/date`; `timedatectl` and `/etc/localtime` decide. The restore ISO sets `Asia/Kolkata`.

## Where the logs are

- `journalctl --user -b` for scripts that use `logger` (`autorotate`) and user units (`rog-wallpaper`, the Spotlight alarms).
- `~/.cache/wallpaper-cycle/wallpaper_cycle.log` for the wallpaper script.
- `/tmp/vx-*.log` while making screenshots; `~/lag-notes.log` for lag snapshots.
""".replace("{TOC}", TOC))


if __name__ == "__main__":
    build()
