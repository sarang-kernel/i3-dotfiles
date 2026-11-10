---
title: "The `rice` command and tools"
parent: "HP desktop and server"
nav_order: 9
---

# The `rice` command and tools

{TOC}

`rice` (`~/.config/hypr/scripts/rice`) is one command for the desktop **and** the server from any terminal, including over SSH: it finds the running Hyprland session by itself (`XDG_RUNTIME_DIR`, the newest `HYPRLAND_INSTANCE_SIGNATURE`, the `wayland-N` socket).

| Command | What it does |
|---|---|
| `rice status [json]` | Server health: services, Tailscale, the media drive, heat, the battery as a UPS |
| `rice meter` | What the desktop itself costs against the 10 % budget |
| `rice shell`, `rice shell classic`, `rice shell hypr`, `rice shell dms` | Show or switch the desktop shell |
| `rice wake`, `rice lock` | Switch the panel on; lock the session |
| `rice shot [file]` | Screenshot (the panel must be on) |
| `rice logs <service>` | Follow a service's log (anything in `server.conf`) |
| `rice backup` | What the newest backup holds |
| `rice remind <10m or 18:30> <text>`, `rice remind list`, `rice remind clear` | Reminders (each one is a transient systemd timer) |
| `rice webapp [name]` | Open a web app in its own window |
| `rice maintenance on [hours]`, `rice maintenance off` | Quiet the server alerts while I work on it |
| `rice vnc`, `rice vnc on`, `rice vnc off` | Remote desktop over Tailscale only (needs wayvnc and a logged-in session) |
| `rice snapshot [label]`, `rice snapshots`, `rice rollback [id]` | Save, list and restore the desktop configuration |
| `rice update [--check] [--aur]`, `rice downgrade <package>` | Snapshot, upgrade and report; go back one cached version of a package |
| `rice doctor [--fix]` | Check for known problems; optionally repair the safe ones |
| `rice msg <text>` | Show a notification on the desktop |


## More tools

- **Theme packs:** `theme.sh pack tokyo-night|gruvbox|nord|rose-pine|kanagawa|everforest`.
- **Safety net:** `rice snapshot` / `rice snapshots` / `rice rollback [id]` for the desktop config (ext4 has no Btrfs snapshots; keeps the newest 20); `rice update [--check] [--aur]` snapshots, upgrades and reports what needs a restart, new `.pacnew` files and server health; `rice downgrade <package>` goes back one cached version; `rice doctor [--fix]` checks for known problems and repairs the safe ones.
- **Desktop:** `Super+Ctrl+R` reminders (`rice remind 10m text`; each is a transient systemd timer, so they cost nothing while waiting), `Super+Alt+B` web apps (`webapps.conf`), `Super+Ctrl+Print` OCR a region, `Super+Alt+Print` decode a QR code, `Super+Backspace` transparency toggle, `Super+Shift+Backspace` gaps toggle, `Super+K` keybinds, `Super+Alt+N` act on the latest notification, `Super+Ctrl+N` dismiss it.
- **Screen recording:** `Super+Print` toggles `wf-recorder` (full), `Super+Shift+Print` (region); `record.sh status` prints Waybar JSON.
- **Screenshots:** `Print` full, `Shift+Print` region, `Ctrl+Print` window, `Alt+Print` region then annotate (satty); saved to `~/Pictures` with the same names as the i3 ones, copied to the clipboard, with a notification preview.

The complete list of scripts with their header comments is on the [script reference page](script-reference.html).
