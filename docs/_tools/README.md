# How these docs are generated

The reference pages are generated from the real files; the prose pages are written by hand in `pages_*.py`.

```bash
export DOCS_WORK=~/docs-work            # src/i3-dotfiles, src/spotlight, src/nvim (copies of the repos), imgs/ (the pictures)
python3 build_all.py                    # writes DOCS_WORK/site/
PRIVACY_FILE=~/my-patterns.txt python3 check.py     # front matter, navigation, links, anchors, Liquid hazards, privacy patterns, coverage
```

The HP pages read `~/.config/hypr` and `~/.local/share/hp-dash` on the machine they run on. `common.py` holds the paths.
Jekyll builds the result on GitHub Pages (theme: just-the-docs, `remote_theme` in `_config.yml`). Nothing here needs Ruby: the checker replaces a local Jekyll build.
