---
title: "Deep search"
parent: "Spotlight"
nav_order: 6
---

# Deep search

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
