"""Generated pages for the HP (Hyprland desktop and home server) section."""
import re
from common import *


def key_pretty(expr):
    e = expr.strip()
    e = e.replace('mod .. " + ', "Super + ").replace('mod .. "', "Super").replace('"', "")
    e = re.sub(r"\s+", " ", e)
    for a, b in (("SHIFT", "Shift"), ("CTRL", "Ctrl"), ("ALT", "Alt"), ("Return", "Enter"), ("Escape", "Esc"), ("BackSpace", "Backspace"), ("slash", "/"), ("grave", "`"),
                 ("bracketright", "]"), ("bracketleft", "["), ("semicolon", ";"), ("period", "."), ("comma", ","), ("minus", "-"), ("equal", "="), ("space", "Space")):
        e = re.sub(rf"\b{a}\b", b, e)
    return e


def parse_binds():
    txt = read(HYPR / "conf/binds.lua")
    rows = []
    section = ""
    for line in txt.splitlines():
        m = re.match(r"^-- ── (.+?) ─", line)
        if m:
            section = m.group(1)
            continue
        m = re.match(r'^bind\(\s*(mod \.\. "[^"]+"|"[^"]+")\s*,(.*)$', line)
        if m:
            rest = m.group(2)
            d = re.search(r',\s*"([^"]+)"\s*\)\s*$', rest)
            rows.append((section or "General", key_pretty(m.group(1)), d.group(1) if d else "", re.sub(r',\s*"[^"]+"\s*\)\s*$', "", rest).strip()[:110]))
    return rows


def script_rows(directory, pattern="*"):
    rows = []
    for f in sorted((HYPR / directory).glob(pattern)):
        if not f.is_file() or f.suffix in (".pyc",):
            continue
        hdr = py_docstring_or_header(str(f)) if f.suffix == ".py" else header_block(str(f))
        first = next((l.strip() for l in hdr if l.strip() and not l.strip().startswith(("shellcheck", "set ", "─", "╭", "│", "╰"))), "")
        rows.append((f"`{directory}/{f.name}`", first[:200], len(read(f).splitlines())))
    return rows


def build():
    rows = parse_binds()
    extra = [("Workspaces", "Super + 1 … 0", "Go to workspace 1-10 (0 is workspace 10)", "loop in binds.lua"),
             ("Workspaces", "Super + Shift + 1 … 0", "Send the window to that workspace", "loop in binds.lua"),
             ("Workspaces", "Super + Alt + 1 … 0", "Send the window there without following it (silently)", "loop in binds.lua"),
             ("Workspaces", "Super + Ctrl + H / L", "Previous / next workspace (same as Ctrl + Left/Right)", ""),
             ("Windows", "Super + H J K L, Super + arrows", "Focus left, down, up, right", "loop in binds.lua"),
             ("Windows", "Super + Shift + arrows", "Move the window", "loop in binds.lua"),
             ("Mouse", "Super + left-drag / right-drag", "Move / resize a floating window", "mouse:272 / mouse:273"),
             ("Mouse", "Super + scroll", "Next / previous workspace", ""),
             ("Resize mode", "H J K L or arrows", "Resize the window by 30 px per press (key repeats); Enter, Esc or Super+R leave", "submap `resize`"),
             ("Media keys", "Volume Up/Down/Mute, Mic mute, Brightness Up/Down", "Through `osd.sh` (swayosd or wpctl fallback); work when the screen is locked", "XF86… binds"),
             ("Media keys", "Play/Pause, Next, Previous", "`playerctl`; work when locked", "XF86Audio… binds"),
             ("Lid", "Lid close / open", "`lid.sh close` and `lid.sh open`: with an external display only the panel is switched off", "switch binds")]
    allrows = [(s, f"`{k}`", d or "(no description)") for s, k, d, _ in rows] + [(s, f"`{k}`", d) for s, k, d, _ in extra]
    order = []
    for s, *_ in allrows:
        if s not in order:
            order.append(s)
    body = ["The Hyprland setup is written in Hyprland's **Lua config** (0.55 and newer). This table is generated from `conf/binds.lua`: every `bind(...)` with its description. The same descriptions feed the live cheat-sheet "
            "(`Super+F1` or `Super+K`, `scripts/keybinds.sh`). Super is **Caps Lock** on this laptop (remapped), so everything is one hand-width away.\n", TOC]
    for s in order:
        body.append(f"\n## {s}\n\n" + table(["Key", "What it does"], [(k, d) for ss, k, d in allrows if ss == s]))
    write("hp/keybindings.md", fm("Keybindings", "HP desktop and server", 3), "# Keybindings (Hyprland on the HP)\n\n" + "\n".join(body))

    s_rows = script_rows("scripts") + script_rows("system") + script_rows("theme", "*.sh") + script_rows("theme", "*.py") + script_rows("shell") + [(f"`{n}`", d, "") for n, d in
              (("doctor.sh", "Checks the dependencies and validates the Hyprland config"), ("install.sh", "One `sudo pacman -S --needed …` of the official packages"), ("report.sh", "Collects versions, config errors, logs and which shell components are up into one file in `~/.cache/hypr/`"))]
    body = ["Every script that is part of the HP desktop and server tooling, with the first line of its own header comment. All of them live in `~/.config/hypr/`.\n", TOC,
            "\n## Scripts\n\n", table(["File", "What it does (from its header)", "Lines"], s_rows)]
    write("hp/script-reference.md", fm("Script reference", "HP desktop and server", 10), "# Script reference (HP)\n\n" + "\n".join(body))

    rice = [l.strip() for l in read(HYPR / "scripts/rice").splitlines() if l.startswith("#   ")]
    rrows = []
    for l in rice:
        m = re.match(r"#\s+(rice [^\s].*?)\s{2,}(.*)$", l)
        if m:
            rrows.append((f"`{m.group(1).strip()}`", m.group(2).strip()))
    return len(rows), len(s_rows), rrows


if __name__ == "__main__":
    a, b, c = build()
    print(a, b, len(c))
