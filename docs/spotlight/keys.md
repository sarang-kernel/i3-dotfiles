---
title: "Keys"
parent: "Spotlight"
nav_order: 2
---

# Keys

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


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
