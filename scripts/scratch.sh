#!/usr/bin/env bash
# scratch: my notepad. One persistent file (~/Documents/scratch.md) in a floating Neovim window that autosaves as I type, so there is
# nothing to save and nothing to lose. Super+N opens it; Super+N again (or :q) closes it. It also opens through Spotlight: type "scratch".
f=$HOME/Documents/scratch.md
[[ -e $f ]] || { mkdir -p "$(dirname "$f")"; : > "$f"; }
if pid=$(pgrep -xo -f "kitty --class scratch .*"); then kill "$pid"; exit 0; fi
exec kitty --class scratch --title scratch -e nvim -c "autocmd TextChanged,TextChangedI,InsertLeave * silent! update" -c "set wrap linebreak" -c "normal! G" "$f"
