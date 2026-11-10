---
title: "Aliases and data files"
parent: "Spotlight"
nav_order: 7
---

# Aliases and data files

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


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
