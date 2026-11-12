---
title: "Using it"
parent: "Spotlight"
nav_order: 1
---

# Using it

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
| `filetype:pdf`, `.pdf`, `kind:pdf in:thesis modified:week` | A **filtered file listing** of *every* matching file, newest first (see below) | `.docx`, `filetype:mov`, `kind:code modified:today` |
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

## Filters (`filetype:`, `.ext`, `in:`, `modified:`)

Any order, combinable, with or without a name. They switch Spotlight to a **sorted-by-time file listing** of up to 10 rows (hidden folders are skipped).

| Filter | Values |
|---|---|
| `filetype:`, `kind:`, `type:`, `ft:` or `ext:` | `folder`, a kind from the table below, or **any extension** (`filetype:mov`, `filetype:.epub`). Several at once with commas: `filetype:mp4,mkv` |
| a bare `.ext` word | The same filter with less typing: `.pdf`, `.docx`, `.mov`. It needs a letter in it, so `.5` stays a number. If nothing has that extension (`.bashrc`), Spotlight carries on with a normal search |
| `in:` | a word that must appear in the path (relative to home), e.g. `in:thesis` |
| `modified:` or `mod:` | `today` (or `day`), `week`, `month` |

| Kind | Extensions |
|---|---|
| `kind:pdf` | .pdf |
| `kind:doc` | .doc, .docx, .odt, .rtf, .pages |
| `kind:slides` | .ppt, .pptx, .odp, .key |
| `kind:sheet` | .xls, .xlsx, .ods, .csv, .tsv |
| `kind:image` | .png, .jpg, .jpeg, .gif, .webp, .svg, .avif, .bmp, .tif, .tiff, .heic |
| `kind:text` | .txt, .md, .org, .rst, .tex, .bib |
| `kind:code` | .py, .rs, .c, .h, .cpp, .js, .ts, .sh, .go, .java, .ipynb, .r |
| `kind:audio` | .mp3, .flac, .ogg, .opus, .wav, .m4a, .aac, .wma |
| `kind:video` | .mp4, .mkv, .webm, .avi, .mov, .m4v, .wmv, .flv, .mpg, .mpeg |
| `kind:archive` | .zip, .tar, .gz, .xz, .7z, .rar, .tgz, .bz2, .zst |
| `kind:ebook` | .epub, .mobi, .azw3, .djvu |


A name that is not a kind is taken as the extension itself, so `filetype:py` and `.py` both list every .py file (`kind:code` is the wider group). The listing has **no cap**: the footer says how many files matched, the list draws 60 rows at a time and loads more as you scroll or keep pressing Down. Add words to narrow it (`.pdf thesis`). Files in the Trash and in hidden folders are included but marked `(trash)` or `(hidden)` after the name, and listed after the ordinary files. Caches, `site-packages`, `.git`, `node_modules` and similar are still left out.

## Bookmarks, Zotero, app actions

- **Bookmarks** (3+ characters, 4 results): Chrome/Chromium `Bookmarks` JSON, Firefox/Zen `places.sqlite` (copied to a temp dir with its WAL first, because the browser keeps it locked), and qutebrowser `quickmarks`/`bookmarks/urls`. Re-read only when a file changed.
- **Zotero** (3+ characters, 4 results): reads `~/Zotero/zotero.sqlite` (or `~/.zotero`) from a cached copy; shows title, first author, year and *PDF attached*. Enter opens the item in Zotero (`zotero://select/library/items/KEY`); Ctrl+Y previews its PDF.
- **App actions** (3+ characters): the *Desktop Actions* of installed apps, such as "New Window".
