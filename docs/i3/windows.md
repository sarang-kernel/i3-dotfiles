---
title: "Windows, workspaces and rules"
parent: "i3 desktop"
nav_order: 5
---

# Windows, workspaces and rules

This page lists the window rules and the look-and-behaviour settings from `i3/config`. The rules are generated from the file.

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


## Window rules (`for_window`)

A rule is `[criteria] commands`: when a window appears and matches the criteria, i3 runs the commands on it. Most of mine make my own helper windows (Spotlight, the power menu, the alarm, the scratchpad) float and centre themselves, and keep dialogs from tiling.


| Matches | i3 does | Why (comment in the config) |
|---|---|---|
| `[class="Pavucontrol"]` | `floating enable` | binds — notifications, bar toggle, small conveniences |
| `[class="Blueberry.py"]` | `floating enable` | binds — notifications, bar toggle, small conveniences |
| `[class="Nm-connection-editor"]` | `floating enable` | binds — notifications, bar toggle, small conveniences |
| `[class="Lxappearance"]` | `floating enable` | binds — notifications, bar toggle, small conveniences |
| `[window_role="pop-up"]` | `floating enable` | binds — notifications, bar toggle, small conveniences |
| `[window_type="dialog"]` | `floating enable` | binds — notifications, bar toggle, small conveniences |
| `[class="^Spotlight$"]` | `floating enable, border none, move position center, move up 260px` | spotlight — Super+D, searches as I type (apps, windows, files, maths, clipboard, actions) |
| `[class="^rog-sync$"]` | `floating enable, resize set 1100 640, move position center` | spotlight — the manual backup runs in a floating terminal so I can see its progress |
| `[class="^RogAlarm$"]` | `floating enable, border pixel 3, move position center` | alarm — a Spotlight timer or reminder rings in a centred box that stays until dismissed |
| `[class="^RogPower$"]` | `floating enable, border none, move position center` | power — Super+Escape opens the power menu (lock, log out, sleep, hibernate, restart, shut down) |
| `[class="^scratch$"]` | `floating enable, resize set 1100 760, move position center` | scratch: my notepad (floating Neovim on ~/Documents/scratch.md, autosaves). Super+N toggles it; also in Spotlight as "scratch". |


## Behaviour and look


| Setting | Value |
|---|---|
| `default_border` | `pixel 2` |
| `default_floating_border` | `pixel 2` |
| `hide_edge_borders` | `smart` |
| `focus_follows_mouse` | `yes` |
| `workspace_auto_back_and_forth` | `yes` |
| `floating_modifier` | `$mod` |
| `tiling_drag` | `modifier titlebar` |
| `font` | `pango:Meslo LGM Nerd Font 11` |


### Colours

The `client.*` lines paint the window borders (border, background, text, indicator, child border). The amber on `client.focused` is my accent colour; the accent script rewrites it, see [Colours, accent and fonts](theme.html).


| Class | Border / background / text / indicator / child border |
|---|---|
| `client.focused` | `#e0a458 #1c1917 #e7dfd3 #e0a458 #e0a458` |
| `client.focused_inactive` | `#3a342e #1c1917 #b5aa9a #3a342e #3a342e` |
| `client.unfocused` | `#2b2622 #14110f #6e655a #2b2622 #2b2622` |
| `client.urgent` | `#e06c5a #e06c5a #0f0d0c #e06c5a #e06c5a` |
| `client.placeholder` | `#14110f #14110f #e7dfd3 #14110f #14110f` |
| `client.background` | `#1c1917` |


## Workspaces

Ten workspaces, named `1`…`10` through `set $ws1 "1"` and so on. Every binding uses `workspace number N`, so the *names* can change without breaking the keys: the display agent can rename them to include app icons (Settings → Top Bar → *Show app icons next to the numbers*), and `workspace_auto_back_and_forth yes` means pressing the number of the workspace you are already on jumps back to the previous one.

## Layout cheat-sheet

i3 is a tree of containers. `Super+V` says "the next window goes *below* this one", `Super+E` toggles the split direction, `Super+S` stacks, `Super+W` makes tabs, `Super+A` focuses the parent container so a layout command can apply to a whole group, `Super+F` is fullscreen, `Super+Shift+Space` floats, and `Super+R` enters resize mode (h/j/k/l or arrows, Enter or Esc to leave). The pictures in the [README](https://github.com/sarang-kernel/i3-dotfiles) show tabbed and stacked.
