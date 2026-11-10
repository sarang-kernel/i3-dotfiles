---
title: "Clipboard history"
parent: "Spotlight"
nav_order: 4
---

# Clipboard history

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


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
