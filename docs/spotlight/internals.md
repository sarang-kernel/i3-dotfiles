---
title: "How it works"
parent: "Spotlight"
nav_order: 10
---

# How it works

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


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
3. `filetype:`/`kind:`/`.ext`/`in:`/`modified:` filters → the filtered file listing only.
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

## Typing never waits for a search

Searches run on one worker thread, not on the window's main loop. Each keystroke (after a 40 ms pause) hands the newest query to the worker, which skips any query that was typed past, so the list can lag behind the box but the box never freezes. If the list on screen is not the answer to the text in the box and I press Enter (or Alt+1 to Alt+9), the key is remembered and fires on the results of the final text, with the footer saying *Still searching*. Typing again cancels the remembered key. That is what stops a fast typist from opening whatever the previous, half-typed query had on top.
