"""Hand-written (and partly generated) pages of the Spotlight section."""
import re
from common import *

P = "Spotlight"
SP = DOTS / "scripts/spotlight.py"


def actions_table():
    t = read(SP)
    rows = re.findall(r'A\("([^"]+)",\s*"([^"]+)",\s*(.+?),\s*"([a-z0-9\-]+)"\)', t)
    out = []
    for title, kw, cmd, icon in rows:
        c = cmd.replace("str(HOME / \".config/i3lock/lock.sh\")", "lock.sh").replace('s + "/', "").replace('"', "").replace("[", "").replace("]", "").replace(", ", " ")
        out.append((title, kw, f"`{c}`"))
    return out


def kinds_table():
    t = read(SP)
    m = re.search(r"KINDS = \{(.*?)\}\n", t, re.S)
    items = re.findall(r'"(\w+)": \(([^)]*)\)', m.group(1))
    return [(f"`kind:{k}`", ", ".join(x.strip().strip('"') for x in v.split(",") if x.strip())) for k, v in items]


def build():
    acts = actions_table()
    kinds = kinds_table()
    write("spotlight/index.md", fm(P, None, 3, children=True, desc="My Spotlight-style launcher for i3"),
          """# Spotlight for i3

I missed macOS's Spotlight, so I built one. **One search box** for apps, open windows, files, maths and unit conversion, clipboard history, timers, emoji, bookmarks, a Zotero library, my own aliases and system actions. It is a small resident GTK3 process in Python, so it appears in about 20 ms, searches *while I type*, and closes itself when it loses focus.

![Spotlight over my desktop](../img/search.png)

The code is one file, `spotlight.py` (about 1500 lines), plus four helpers: `rog-ui.sh` (the client), `alarm.py` (the timer window), `power-menu.py` and `rg-pre.sh` (PDF text for deep search). It lives in its own repo, [`sarang-kernel/spotlight`](https://github.com/sarang-kernel/spotlight), and is also copied into my dotfiles (`apps/spotlight/` and `scripts/`).

## Pages

| Page | What you get |
|---|---|
| [Using it](usage.html) | Every kind of query, with examples |
| [Keys](keys.html) | Every key, in the list view, the home view, the app grid and the preview |
| [Actions](actions.html) | The system actions it offers (lock, performance mode, update …) |
| [Clipboard history](clipboard.html) | How it records and searches what I copy |
| [Timers and reminders](timers.html) | `timer 25m`, `remind 15:30 …` and how alarms work |
| [Deep search](deep-search.html) | Searching *inside* PDFs, notes and code |
| [Aliases and data files](data-files.html) | Everything it reads and writes |
| [Appearance and settings](appearance.html) | Theme, accent, transparency |
| [Power menu and alarm window](power-menu.html) | The two small companion windows |
| [How it works](internals.html) | The resident process, the FIFO, scoring, the window dance |
| [Install](install.html) | Standalone install, dependencies, i3 lines |
| [Troubleshooting](troubleshooting.html) | Things that went wrong |
""")

    write("spotlight/usage.md", fm("Using it", P, 1), """# Using it

{TOC}

Press **Super+D**. Start typing. The first row is selected; press **Enter**. That is the whole interface.

With an empty box you see a **home view**: my last four apps as a tile row, my last four files, and (after a week without a backup) a hint *"Your last backup was N days ago, click to back up"*. Switch this off in Settings → Spotlight → *Recents when opened* (`SPOT_RECENTS`).

## Everything you can type

| You type | You get | Example |
|---|---|---|
| a name | **Apps** (most used first), **open windows**, **files and folders** (6 at most, via `plocate`), **bookmarks** (3+ characters), **Zotero items** (3+ characters), **app actions** such as *Firefox: New Private Window* (3+ characters), my **aliases**, **actions** (2+ characters), and a web-search row | `firef`, `thesis` |
| `=2+2`, `15% of 80`, `5 km in mi`, `20 c in f`, `sqrt(2)` | The answer as the first row; **Enter copies it** | `=2+2*8` → `18` |
| `c word` or `clip word` | Clipboard history, filtered | `c token` |
| `w name` | Windows only, with a small picture of each one on the visible workspace | `w term` |
| `> command` | Run a shell command (Enter) or run it in a terminal and keep it open (Ctrl+Enter) | `> uname -a` |
| `:name` | Emoji search by Unicode name; Enter copies the character | `:smile` |
| `timer 25m`, `timer 1h30m`, `timer 90s`, `timer 10` | A countdown that rings in a window; a bare number means minutes | `timer 25m` |
| `remind in 10m call back`, `remind 15:30 stand up`, `remind 3pm tea`, `remind tomorrow 9am email` | A reminder | |
| `timers` (or `alarms`, `reminders`) | List pending ones; Enter cancels the selected | |
| `kind:pdf in:thesis modified:week` | A **filtered file listing**, newest first (see below) | `kind:code modified:today` |
| `/ phrase` | **Deep search**: look *inside* PDFs, notes, code | `/ eigenvalue` |
| `h`, `hist`, `history` (+ text) | My shell history; Enter copies the command, Ctrl+Enter runs it in a terminal | `h rsync` |
| a URL (`https://…` or `www.…`) | An *Open …* row at the top | |
| anything else | A *Search the web for …* row at the bottom (DuckDuckGo), and, for 3+ characters with no file hits, a *Search inside documents* row that starts the deep search when you press Enter | |

## Maths and units

Maths goes to `qalc` (`libqalculate`). Before that a small normaliser says what people mean:

- `15% of 80` becomes `(15/100) * 80` (a product, not a conversion).
- `in` or `as` after a number and unit is a *conversion*, not inches: `5 km in mi` → `5 km to mi`.
- `c`, `f` and `k` after a number, or after `to`, are temperatures: `20 c in f` works, as does `100 f to c`.
- When qalc splits a long conversion into mixed units (`3 mi + 188 yd + …`) Spotlight asks again as a ratio and shows **one number with the unit** (`3.106855961 mi`).

The row is shown only if the text looks like maths (it starts with `=`, contains digits with an operator, has `number unit to|in|as unit`, or starts with `sqrt sin cos tan log ln exp abs`). If qalc errors, nothing is shown.

## Files

`plocate` is asked for the query (spaces become `*`), limited to my home folder, `/mnt`, `/media`, `/run/media` and `/srv`. These are skipped as noise: `site-packages`, virtual environments, `.cache`, `.git`, `node_modules`, `__pycache__`, browser and Electron profiles, `~/.local/share`, `~/.local/state`, `.cargo/registry`, `.rustup`, `.nvm`, pnpm stores, Docker/Snap/Steam/Wine folders, Trash, and `/usr/share`, `/var`, `/opt`.
Ranking: name match quality, minus penalties for hidden folders in the path, for depth, and for dot-files; a bonus for being in my home folder. Each row shows kind, size and modified time (*Today, 14:02*, *Yesterday*, or a date) and the folder. The recent-files list on the home screen comes from `~/.local/share/recently-used.xbel`.

**Enter** opens with `xdg-open`, **Ctrl+Enter** opens the containing folder, **Alt+Enter** copies the file *as a file* (see [Keys](keys.html#copying)).

## Filters (`kind:`, `in:`, `modified:`)

Any order, combinable, with or without a name. They switch Spotlight to a **sorted-by-time file listing** of up to 10 rows (hidden folders are skipped).

| Filter | Values |
|---|---|
| `kind:` or `type:` | `folder` and the kinds in the table below |
| `in:` | a word that must appear in the path (relative to home), e.g. `in:thesis` |
| `modified:` or `mod:` | `today` (or `day`), `week`, `month` |

""" + table(["Kind", "Extensions"], kinds) + """

`kind:py` does **not** exist; use `kind:code`. An unknown kind returns no results (that is the "No results" you get).

## Bookmarks, Zotero, app actions

- **Bookmarks** (3+ characters, 4 results): Chrome/Chromium `Bookmarks` JSON, Firefox/Zen `places.sqlite` (copied to a temp dir with its WAL first, because the browser keeps it locked), and qutebrowser `quickmarks`/`bookmarks/urls`. Re-read only when a file changed.
- **Zotero** (3+ characters, 4 results): reads `~/Zotero/zotero.sqlite` (or `~/.zotero`) from a cached copy; shows title, first author, year and *PDF attached*. Enter opens the item in Zotero (`zotero://select/library/items/KEY`); Ctrl+Y previews its PDF.
- **App actions** (3+ characters): the *Desktop Actions* of installed apps, such as "New Window".
""".replace("{TOC}", TOC))

    write("spotlight/keys.md", fm("Keys", P, 2), """# Keys

{TOC}

Most keys have a vim-style twin so I do not have to leave the home row. The footer line of the list view prints the main ones.

## In the result list

| Key | What it does |
|---|---|
| `Enter` | Run or open the selected row |
| `Ctrl+Enter` or `Shift+Enter` | **Reveal**: open the folder of a file; run a shell-history command in a terminal; run a `>` command in a terminal and wait |
| `Alt+Enter` | **Copy** (see below) |
| `Ctrl+C` | **Closes Spotlight**, like `Esc`. The footer text and my README say it copies, but see the known issue below |
| `Up` / `Down`, `Ctrl+K` / `Ctrl+J`, `Ctrl+P` / `Ctrl+N`, `Tab` / `Shift+Tab` | Move the selection |
| `Alt+1` … `Alt+9` | Run that row (the number is shown, faintly, on the selected row) |
| `Ctrl+Y`, or **hold Space** | Preview the selected file (see [Preview](#preview)) |
| `Alt+A` | Browse all apps |
| `Ctrl+U` | Clear the search box |
| `Esc` or `Ctrl+[` | Close Spotlight |

**Known issue:** the code has a copy rule for `Ctrl+C` (copy the highlighted result, unless text in the box is selected), but an earlier rule in the same key handler treats `Ctrl+C` like `Esc` and closes the window first, so the copy rule never runs. Use `Alt+Enter` to copy. (The one-word fix would be removing `Gdk.KEY_c` from the close rule in `Spot.on_key`.)

## Copying

One copy key for everything. **A file copies as the file itself:** an image becomes a picture on the clipboard (up to 40 MB), a text-like file (`.md .tex .bib .org .py .sh .R .qmd .csv .txt`, JSON, XML, under 2 MB) copies its **text**, and any other file is put on the clipboard in the GNOME *copied files* format so it pastes as a file into a file manager, a chat or an email. A calculator row copies the number, an emoji row the character, a clipboard row its text, a bookmark its URL, a shell-history row the command.

## Holding Space

A quick tap types a space as usual. **Holding Space for 380 ms** on a result that has a file behind it opens the preview (like macOS Quick Look); releasing Space goes back. If there is nothing to preview, the held space is typed after all. Any other key pressed while Space is pending types the space first, so typing order is preserved.

## Preview

`Ctrl+Y` (or holding Space) on a selected file shows it inside the same window, widened to 1000 px:

| File type | What you see |
|---|---|
| Image | The picture, scaled to fit 960×560 |
| PDF | Page 1 rendered at 80 dpi (`pdftoppm`) |
| Text, code, config, logs, notebooks | The first 60 000 bytes, monospaced |
| Folder | The first 200 entries (folders marked with `/`) |
| Anything else | Kind, size and date, and *No preview for this kind of file* |

In the preview: `Esc` or `Ctrl+Y` go back to the list (and re-select the row), `Enter` opens the file, `Up` / `Down` scroll by 60 px, `Page Up` / `Page Down` by 420 px.

## Home view

The tile row and the file list: `Left` / `Right` (or `Ctrl+H` / `Ctrl+L`) move along the tiles, `Up` / `Down` move between the tile row and the file list. `Enter` opens; `Ctrl+Enter`/`Alt+Enter` work as in the list.

## All apps (`Alt+A`)

An alphabetical grid, four columns, scrolling inside a 560 px window (1000 px wide). Arrow keys (and `Ctrl+J/K/N/P`) move by rows of four, `Left` / `Right` by one; `Enter` launches; **`Esc` goes back to the home view first**, and a second `Esc` closes. Typing still searches.
""".replace("{TOC}", TOC))

    write("spotlight/actions.md", fm("Actions", P, 3), """# Actions

Actions are rows that *do* something instead of opening something. They appear for queries of **two or more characters** that match the title or its keywords; the list below is generated from `action_items()` in `spotlight.py`.
Many call my other scripts (see [Scripts](../scripts/)), so without those scripts the rows are missing or do nothing. Recently used actions float up (frecency, see [How it works](internals.html#ranking)).

""" + table(["Action shown", "Keywords that find it", "What it runs"], acts) + """

Notes:

- **Hibernate** is only offered when the kernel command line contains `resume_offset` (hibernation is set up).
- *System update* and *Roll back the last update* open a floating terminal (class `rog-sync`) running `rog-update.sh` so I can read the Arch news and watch pacman.
- Performance-mode actions change `MODE_AC` or `MODE_BAT` for the power source I am on (see [Power scripts](../scripts/power-display.html#power-modesh)).
""")

    write("spotlight/clipboard.md", fm("Clipboard history", P, 4), """# Clipboard history

{TOC}

Spotlight is also my clipboard manager. The resident process listens for the GTK clipboard's `owner-change` event, so **there is no polling daemon**: when something is copied, the process stores it.

## What is stored

| | |
|---|---|
| Text | Every non-empty text up to 500 000 characters. Copying the same text again moves it to the top instead of duplicating it |
| Images | When there is no text but an image (a screenshot, an image copied in a browser) it is saved as a PNG named by the first 20 hex digits of its SHA-1, under `~/.local/state/spotlight/clipimg/`, up to 40 MB each |
| Limits | 3000 entries in total, of which at most 300 images; older ones are dropped (image files deleted) |
| Where | `~/.local/state/spotlight/clipboard.json`, written atomically with mode **0600**; images mode 0600 |

Because everything I copy is kept, **passwords I copy are kept too**. Nothing is encrypted at rest. If that matters, clear the history file (`rm ~/.local/state/spotlight/clipboard.json; rm -r ~/.local/state/spotlight/clipimg`) and restart Spotlight (`rog-ui.sh restart`).

## Using it

- **`Super+Shift+V`** opens Spotlight pre-filled with `c ` (the list of recent entries).
- Or type `c word` / `clip word` in the normal box. The filter is a case-insensitive substring match on the text. Words like `image`, `img`, `screenshot`, `picture`, `png` show the images.
- A text entry shows its first line (140 characters) and `(+N lines)` for multi-line copies. An image shows a thumbnail and its size (`Image 1920 × 1080`).
- **Enter** puts the entry back on the clipboard (paste it with Ctrl+V). For an image it pipes the PNG back with `xclip -t image/png`. **Ctrl+Enter** on an image opens the file.

## Importing greenclip

I used greenclip before; `spotlight.py --import-greenclip` imports its history one entry at a time through `greenclip print`, oldest first, spreading the timestamps 10 minutes apart because greenclip kept none. (Imported images have no recorded size; it is read from the file once.)

## Memory

The history is kept in memory by the resident process (`_clip_cache`) so searching never re-reads the file. The process restarts itself when its resident memory exceeds 150 MB; the history is on disk, so nothing is lost.
""".replace("{TOC}", TOC))

    write("spotlight/timers.md", fm("Timers and reminders", P, 5), """# Timers and reminders

{TOC}

## Typing them

| You type | Meaning |
|---|---|
| `timer 25m` | Ring in 25 minutes |
| `timer 1h30m`, `timer 1 hour 15 min`, `timer 90s` | Hours, minutes, seconds, in any combination; units `h hr hrs hour hours`, `m min mins minute minutes`, `s sec secs second seconds` |
| `timer 10` | A bare number is **minutes** |
| `timer 25m tea` | The text after the time is the label |
| `remind in 10m call back` | Reminder after 10 minutes |
| `remind 15:30 stand up` | Reminder at 15:30 today (tomorrow if that time has passed) |
| `remind 3pm tea`, `remind 3:30 pm …` | 12-hour times; `am`/`pm` handled |
| `remind tomorrow 9am email` | `tomorrow` (or `tmrw`) shifts the day |
| `remind me to …` | The words *me* and *to* are optional |
| `timers`, `alarms`, `reminders`, `timer`, `remind` | List what is pending; **Enter on a row cancels it** |

Limits: a timer must be longer than zero and at most 7 days. A lone number in a `remind` is not a time of day, so `remind 5 x` is not accepted.

The result row says when it will ring (*Rings at 13:12 · press Enter to start*). Nothing is scheduled until you press Enter.

## How an alarm works

1. Spotlight starts a **transient systemd user timer** with `systemd-run --user --collect --unit=rog-alarm-<timestamp> --on-active=<ms> --timer-property=AccuracySec=10ms`, passing `DISPLAY`, `XAUTHORITY`, `XDG_RUNTIME_DIR` and the D-Bus address with `--setenv`. It fires about 0.4 s early, which is how long the alarm window needs to start.
2. The unit runs `alarm.py "label"`.
3. Spotlight also records the alarm in `~/.local/state/spotlight/alarms.json` (unit name, message, due time) so it can list it; entries more than a minute past due are pruned on the next write.
4. Because it is a systemd unit, **the alarm survives closing Spotlight and even logging out of Spotlight's process**; it does not survive a reboot (the timer is transient).

## The alarm window

A centred card (class `RogAlarm`, i3 rule `border pixel 3, move position center`) showing the message with an alarm-clock glyph. It stays **until dismissed**: `Enter` or `Esc`. `S` **snoozes five minutes** (it schedules another transient timer and records it). A sound plays up to four times (`/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga` through `paplay`, 1.5 s apart) unless `ALARM_SOUND=0` (Settings → General → *Play a sound when one rings*).
""".replace("{TOC}", TOC))

    write("spotlight/deep-search.md", fm("Deep search", P, 6), """# Deep search

Normal search finds *files by name*. Deep search finds files by **what is inside them**.

## Starting it

- Type **`/ phrase`** (a slash and a space): Spotlight goes straight to the deep search.
- Or type a normal query of 3+ characters; if it found no files at all, a row *Search inside documents for "…"* appears at the bottom (it is deliberately ask-first because the first run can be slow). Press Enter on it.

While it runs the list says *Searching inside documents for "…"…* and you can keep typing; stale results are discarded.

## What it does

`ripgrep` (`rg`) runs with: `--no-heading --with-filename --line-number --max-count 1` (one hit per file), `-i -F` (case-insensitive, literal text, not a regex), `--max-columns 240`, only these file types: `md txt tex pdf org rst bib csv html ipynb qmd R py`, skipping `node_modules .git site-packages __pycache__ .venv venv .obsidian .trash`. It gives up after 40 seconds and shows at most 12 matches.
Each result is a file with the matching line and its folder; **Enter** opens the file, **Ctrl+Enter** opens its folder, **Alt+Enter** copies it.

## PDFs

`rg` cannot read PDFs, so it is given `--pre ~/.config/scripts/rg-pre.sh --pre-glob '*.pdf'`. The helper extracts the text once with `pdftotext -layout` and caches it in `~/.cache/spotlight/pdf/<md5 of path+mtime>`; every later search reads the cached text. **The first deep search over many PDFs is slow; after that it is fast.** Needs `poppler`.

## Where it looks

Folders listed one per line in `~/.config/spotlight/roots`; if the file is missing or none of the folders exist, `~/notes` and `~/Documents`. Change them in Settings → Spotlight → *Deep search folders* (a checklist dialog; it also offers `Desktop Pictures Downloads Development Music Videos Zotero .ssh .config` as candidates and an *Add another folder* button).
""")

    write("spotlight/data-files.md", fm("Aliases and data files", P, 7), """# Aliases and data files

{TOC}

## Aliases

`~/.config/spotlight/aliases` holds my own shortcuts, one per line: **`name = target`**. Lines starting with `#` are comments. The file is created with examples the first time Spotlight looks for it.

```text
# name = what to open (a folder, a file, a web address, or a command)
thesis = ~/Documents/thesis
overleaf = https://www.overleaf.com/project
gpu = kitty -e nvidia-smi
scratch = /home/sarang/.config/scripts/scratch.sh
```

- An alias row appears when the query **equals the name, or is the beginning of it** (case-insensitive: typing `the` finds `thesis`); an exact match scores highest and goes to the top.
- The target is a **folder or file** (opened with `xdg-open`) if the path exists, a **URL** if it starts with `http(s)://` (opened in the browser), otherwise a **shell command** (`sh -lc`).
- `~` is expanded.
- My `scratch` alias opens the [notepad](../scripts/session.html#scratchsh).

## Files Spotlight reads

| File | What |
|---|---|
| `~/.config/rog/settings.env` | `APPEARANCE`, `ACCENT_MODE`, `ACCENT_HEX`, `SPOT_OPACITY`, `SPOT_RECENTS`, `NIGHT_START`, `NIGHT_END` (and what the actions change) |
| `~/.config/spotlight/aliases` | Aliases (above) |
| `~/.config/spotlight/roots` | Folders for deep search |
| `~/.config/spotlight/sync.list` | Folders for the backup (written by the Settings backup dialog) |
| `~/.local/share/recently-used.xbel` | Recent files for the home view |
| `~/.bash_history` | Shell-history search |
| Browser bookmark files | Chrome/Chromium `Bookmarks`, Firefox/Zen `places.sqlite`, qutebrowser `quickmarks` and `bookmarks/urls` |
| `~/Zotero/zotero.sqlite` or `~/.zotero/zotero.sqlite` | Zotero search |
| `plocate`'s database | File search (keep it fresh with `sudo updatedb`; a timer normally does) |

## Files Spotlight writes

All under `~/.local/state/spotlight/` (or `$XDG_STATE_HOME/spotlight`):

| File | What |
|---|---|
| `history.json` | Usage counts and last-used times per app, file, action and alias (for ranking) |
| `clipboard.json`, `clipimg/` | [Clipboard history](clipboard.html) (mode 0600) |
| `alarms.json` | Pending timers and reminders |
| `last-backup` | Unix time of the last successful backup (for the 7-day hint) |
| `zotero.sqlite` | A cached copy of the Zotero database (the original is locked while Zotero runs) |

And in `$XDG_RUNTIME_DIR`: `rog-ui.fifo` and `rog-ui.pid` (the daemon's command pipe and pid), `spotlight-preview.png` (a temporary page-1 render). In `~/.cache/spotlight/pdf/`: cached PDF text.

To reset what Spotlight has learned, delete `history.json` and restart the daemon.
""".replace("{TOC}", TOC))

    write("spotlight/appearance.md", fm("Appearance and settings", P, 8), """# Appearance and settings

All of these live in `~/.config/rog/settings.env` and have rows in **Settings → Spotlight** and **Settings → General**.

| Setting | Values | Effect |
|---|---|---|
| `SPOT_OPACITY` | 35-100 in the slider (30-100 accepted), default 62 | How opaque the box is. Lower is more see-through. Applied the next time it opens |
| `APPEARANCE` | `light`, `dark`, `schedule` | Light palette, dark palette, or dark between `NIGHT_START` and `NIGHT_END` |
| `ACCENT_MODE`, `ACCENT_HEX` | `amber`, `wallpaper`, `custom` | The selection and caret colour |
| `SPOT_RECENTS` | `1`/`0` | The home view with recent apps and files |

## How the look is built

The CSS is written once for the **light palette with the amber accent** (`rgba(238,233,224,alpha)` background, `#2a251e` text, `#b86f12` caret) and then **rewritten on demand**: for dark mode the light colours are replaced by dark ones, the accent is swapped for the chosen one (the caret is derived: darker in light mode, lighter in dark mode), and `__ALPHA__` is replaced by the opacity.
Because Spotlight and Settings share one process in the daemon, every rule is **prefixed with `window.spotlight`** (`scope()`), so Spotlight's styles can never leak into the Settings window.

Rounded corners (26 px) come from picom's `corner-radius-rules` (see [Compositor](../i3/compositor.html)); the blur behind the box is picom's too, which is why `picom-bat.conf` has a rule that blurs *only* Spotlight.

## Geometry

860 px wide (1000 px for the preview and the app grid), centred on the primary monitor, 15 % of the screen height from the top. i3 places it (`for_window [class="^Spotlight$"] floating enable, border none, move position center, move up 260px`), and the program re-places itself with `i3-msg … move absolute position` after every width change.
""")

    write("spotlight/power-menu.md", fm("Power menu and alarm window", P, 9), """# Power menu and alarm window

Two small windows that share Spotlight's look.

## Power menu (`Super+Esc`)

![The power menu](../img/power.png)

`power-menu.py` shows six tiles in one row: **Lock, Log out, Sleep, Hibernate, Restart, Shut down**.

| Key | |
|---|---|
| `h`, `l`, `Left`, `Right`, `Tab`, `Shift+Tab` | Move |
| `1` … `6` | Pick (and run) |
| `Enter` or `Space` | Run the selected tile |
| `Esc` or `q` | Close |
| `Super+Esc` again | Closes it (it finds another copy of itself and ends it) |

**Lock** and **Sleep** run at once. **Log out, Hibernate, Restart and Shut down need a second Enter**: the first press turns the tile solid and the line underneath says what will happen (for example *Press Enter again to hibernate (saves to disk, powers off)*). Moving away disarms it, so a slip never ends the session.
The first line shows host name, uptime and battery (`battery 63% (discharging)`). Hibernate is hidden when the kernel command line has no `resume=`.
The commands are `lock.sh`, `i3-msg exit`, `systemctl suspend`, `systemctl hibernate`, `systemctl reboot` and `systemctl poweroff`. The window class is `RogPower` (i3 rule: floating, no border, centred), and the colours follow `APPEARANCE` and the accent.

## Alarm window

The alarm card that a timer or reminder raises is described on [Timers and reminders](timers.html#the-alarm-window).
""")

    write("spotlight/internals.md", fm("How it works", P, 10), """# How it works

{TOC}

## One process, two modes

`spotlight.py` runs in three ways:

| Command | Meaning |
|---|---|
| `spotlight.py` | A one-shot window; the process ends when it closes |
| `spotlight.py --daemon [command]` | **Resident mode**: the window is built once, hidden, and shown when asked. This is what i3 starts |
| `spotlight.py --search words…` | **Headless**: prints the results the box would show, with scores. I use it for testing |
| `spotlight.py --import-greenclip` | One-off import of the old clipboard manager's history |

In resident mode the process creates `$XDG_RUNTIME_DIR/rog-ui.fifo` (mode 0600) and writes its pid to `rog-ui.pid`. `rog-ui.sh spotlight|clip|apps` writes a command into the FIFO; a GLib `io_add_watch` on the FIFO calls `handle()`. That is why opening takes about 20 ms: nothing is started.
The process also loads all apps once (and reloads them when `Gio.AppInfoMonitor` reports a change), connects to the clipboard `owner-change` signal, and keeps the clipboard history in memory.
A second `--daemon` start hands its command to the running process and exits, so there is only ever one resident instance. When the window is dismissed and the process has grown past **150 MB** resident memory it `exec`s itself again (everything important is on disk).
The **Settings app is not resident**: `rog-ui.sh settings` starts it on demand.

## The window dance

A transparent (ARGB) top-level window that is invisible (`opacity 0`) until three things have happened: it is mapped, i3 has moved it to its place, and it has drawn its first frame. Only then is it revealed. This avoids the first-frame garbage, the jump, and a blurred blank box that an ARGB window shows if revealed too early.
It closes itself 150 ms after focus-out (`close_if_unfocused`), and ignores that if it is still the active window.

## Search pipeline

Typing waits 90 ms after the last keystroke (debounce), then calls `search(q)`:

1. `>` → the *Run* row only.
2. Timer/reminder syntax → alarm rows only.
3. `kind:/in:/modified:` filters → the filtered file listing only.
4. `:` → emoji only. `h/hist/history` → shell history. `c/clip` → clipboard. `w` → windows.
5. Otherwise **everything is gathered** (calculator, apps, windows, actions, files, web; then aliases, app actions, bookmarks and Zotero, each wrapped in its own try/except so one broken source cannot break the box) and, for 3+ characters with no file hits, a *Deep* row is added.
6. The union is sorted by score and cut to **10 rows** (`MAXROWS`).

A leading `/ ` bypasses all of that and runs the deep search in a worker thread.

## Ranking

`match(q, text)`: every word of the query must match; a **prefix** match scores 100, a match at the start of a word (after space, `-`, `_`, `.` or `/`) 80, a substring 60; the score is the average over the words, zero if any word misses.

| Source | Score |
|---|---|
| Calculator, timers | 1000 |
| Alias (exact name / prefix) | 1500 / 900 |
| URL row | 900 |
| App | 20 + match (name, or app id × 0.6, keywords × 0.7, description × 0.35 when they match well) + frecency |
| Open window | 35 + match (title, or window class × 0.9) |
| Action | 12 + match (title, or keywords × 0.8) |
| File | half the name-match score, minus 15 per hidden folder, 1.5 per path level and 8 for a dot-file, plus 10 for being under home |
| Bookmark, Zotero | 28 + match × 0.5, and 40 + match × 0.4 |
| Web search row | −100 (always last) |
| Deep-search row | −50 |

**Frecency** adds up to 40 points: `min(40, 8 × uses) / (1 + age_in_days / 14)`: each use is worth 8 points, and the bonus halves roughly every two weeks. It is recorded in `history.json` whenever a row is run.

## Two clipboards

Spotlight talks to the X clipboard through GTK (for recording) and through `xclip` subprocesses (for putting things back and for the special file formats). Starting the daemon from the desktop session matters because it passes its environment (`DISPLAY`, `XAUTHORITY`, D-Bus address) to every program it launches.

## Launching apps

Apps come from `Gio.AppInfo.get_all()` filtered by `should_show()`. A terminal app (`Terminal=true` in the `.desktop` file) is started as `kitty sh -lc <command>` with the field codes removed; other apps use GIO's launch context; if that raises, a shell fallback runs the command line. Every started process gets its own session and is reaped by a thread, so no `<defunct>` children pile up in the long-lived process.

## Source map

| Function / class | Job |
|---|---|
| `match`, `frecency`, `bump` | Matching and learning |
| `apps_for`, `launch_app`, `load_apps` | Apps |
| `windows_for`, `window_thumb` | Open windows through `i3-msg -t get_tree`; thumbnails with ImageMagick `import -window`, cached 8 s, only in `w ` mode, at most 8 |
| `action_items`, `actions_for` | System actions |
| `files_for`, `filtered_files`, `recent_files` | Files |
| `calc_for`, `calc_norm` | Maths |
| `load_clip`, `store_clip`, `store_clip_image`, `clip_changed`, `clip_for` | Clipboard history |
| `parse_duration`, `parse_clock`, `alarm_items`, `schedule_alarm` | Timers |
| `alias_items`, `bookmark_items`, `zotero_items`, `emoji_items`, `history_items`, `web_for` | The smaller sources |
| `deep_items`, `deep_roots` | Deep search |
| `class Spot` | The window: home view, list view, app grid, preview, key handling, placement |
| `daemon()`, `main()` | Resident mode and command line |
""".replace("{TOC}", TOC))

    write("spotlight/install.md", fm("Install", P, 11), """# Install

{TOC}

## From the standalone repo

```bash
git clone https://github.com/sarang-kernel/spotlight
cd spotlight
./install.sh
```

`install.sh` copies `spotlight.py`, `rog-ui.sh`, `alarm.py`, `rg-pre.sh` and `power-menu.py` to `~/.config/scripts` (an existing different copy is saved as `*.old`) and prints the i3 lines to add:

```text
exec_always --no-startup-id ~/.config/scripts/rog-ui.sh start
bindsym $mod+d exec --no-startup-id ~/.config/scripts/rog-ui.sh spotlight
bindsym $mod+Shift+v exec --no-startup-id ~/.config/scripts/rog-ui.sh clip
bindsym $mod+Escape exec --no-startup-id python3 ~/.config/scripts/power-menu.py
for_window [class="^Spotlight$"] floating enable, border none, move position center, move up 260px
for_window [class="^RogPower$"] floating enable, border none, move position center
for_window [class="^RogAlarm$"] floating enable, border pixel 3, move position center
```

Reload i3 afterwards.

## Dependencies

Required: `python-gobject`, `gtk3`, `libqalculate` (for `qalc`), `plocate`, `xclip`, `i3-wm` (it talks to i3 through `i3-msg`).
Optional: `ripgrep` and `poppler` (deep search, PDF preview), `imagemagick` (window thumbnails), `kitty` (terminal apps and `Ctrl+Enter` runs), a Papirus or Adwaita icon theme, `libnotify` is *not* needed.

Programs the **actions** call (performance modes, night tint, update, backup) belong to my wider setup; see [Actions](actions.html). Without them those rows are simply missing or do nothing.

## Running it

```bash
~/.config/scripts/rog-ui.sh start      # start the resident process
~/.config/scripts/rog-ui.sh restart    # after editing the script
~/.config/scripts/rog-ui.sh quit
python3 ~/.config/scripts/spotlight.py --search 15% of 80    # headless test
```

## Licence

None chosen yet (the standalone repo says so).
""".replace("{TOC}", TOC))

    write("spotlight/troubleshooting.md", fm("Troubleshooting", P, 12), """# Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `Super+D` does nothing | The daemon is not running or its FIFO is stale. `rog-ui.sh restart`, then try again. Run `python3 ~/.config/scripts/spotlight.py` in a terminal for the traceback |
| It opens, but launching apps fails | It was started over ssh or before the session had `DISPLAY`/D-Bus. Restart it from a terminal *inside* the desktop |
| File search finds nothing new | `plocate` is stale: `sudo updatedb` |
| `kind:py` shows *No results* | The kinds are `pdf doc slides sheet image text code audio video archive folder`; use `kind:code` |
| *Search inside documents* is slow the first time | PDFs are being converted to cached text; later searches are fast |
| Calculator row does not appear | The text did not look like maths, or `qalc` printed an error; try `=` in front |
| Clipboard history is empty after a reboot | It is not: it is on disk. If `~/.local/state/spotlight/clipboard.json` is gone or unreadable it starts empty. A history file that is not valid JSON is ignored (starts empty) |
| An entry I copied is missing | Texts over 500 000 characters and images over 40 MB are skipped; empty or whitespace-only texts too |
| Window thumbnails missing in `w ` | Only windows on the visible workspace can be captured, only the first 8, and `imagemagick` must be installed |
| It looks too transparent / unreadable | Settings → Spotlight → *Transparency*; blur only exists when picom runs |
| Spotlight is blank for a moment | The first frame is hidden on purpose (see [How it works](internals.html#the-window-dance)); a slow compositor makes the delay visible |
| High memory | It restarts itself above 150 MB after it closes; `rog-ui.sh restart` does it by hand |
| The *Settings* window looks unstyled | The two windows share a process; Spotlight's CSS is scoped to `window.spotlight`. If Settings looks wrong, start it fresh (`pkill -f settings.py`) |

Logging: Spotlight prints nothing by default. For a trace run it from a terminal. The resident process's stderr goes to `/dev/null` (`rog-ui.sh` redirects it), so use a terminal run for debugging.
""")


if __name__ == "__main__":
    build()
