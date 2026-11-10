---
title: "Install"
parent: "Spotlight"
nav_order: 11
---

# Install

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


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
