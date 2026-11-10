"""Generated pages for the scripts section (reference cards for every script, settings.env reference, index)."""
import re
from common import *
from prose_scripts import PROSE

SD = DOTS / "scripts"

TOOLS = ["xrandr", "xinput", "xset", "xsetroot", "xsetwacom", "xdotool", "xclip", "scrot", "magick", "feh", "pactl", "brightnessctl", "upower", "powerprofilesctl",
         "asusctl", "jq", "i3-msg", "polybar-msg", "rofi", "tesseract", "systemd-run", "systemctl", "rsync", "ssh", "onboard", "gsettings", "qalc", "plocate", "rg",
         "pdftotext", "pdftoppm", "notify-send", "monitor-sensor", "kitty", "btop", "paplay", "vainfo", "logger", "pacman", "pacdiff", "fuser", "import", "setsid",
         "loginctl", "i3lock", "polybar", "picom", "python3", "curl", "fuser"]

GROUPS = {
    "power-display": ("Power, display and input", 3,
                      ["power-watch.sh", "power-mode.sh", "display-agent.py", "nightlight.sh", "autorotate.sh", "input-apply.sh", "accent.sh", "wallpaper-timer.sh"],
                      "The scripts that react to the power source, the screen and the input devices. Most of them are started by i3 and keep running."),
    "session": ("Session helpers", 4,
                ["caffeine.sh", "autocaffeine.sh", "pin.sh", "tablet.sh", "scratch.sh", "shot.sh", "ocr.sh", "osd.sh", "keys.sh", "sysmon.sh", "camera.sh",
                 "power-menu.py", "alarm.py", "login-apply.sh", "pen-setup.sh", "lag-now"],
                "Small tools behind my keybindings and the bar: caffeine, screenshots, OCR, the power menu, the scratchpad and so on."),
    "system": ("System, backup and update tools", 5,
               ["rog-update.sh", "sync-server.sh", "login-bg.sh", "vaapi-check.sh", "wallpaper-cycle.sh", "rg-pre.sh", "rog-ui.sh"],
               "Scripts that touch the wider system: updates and rollback, the backup to the home server, wallpaper plumbing and the client for Spotlight's resident process."),
}
EXTRA_FILES = {"wallpaper-cycle.sh": DOTS / "wallpaper-config/wallpaper-cycle.sh", "toggle-touchpad.sh": DOTS / "i3/toggle-touchpad.sh"}
SESSION_EXTRA = ["toggle-touchpad.sh"]


def settings_keys():
    txt = read(SD / "settings.py")
    m = re.search(r"DEFAULTS = \{(.*?)\n\}|DEFAULTS = \{(.*?)\}\n", txt, re.S)
    block = m.group(1) or m.group(2)
    return dict(re.findall(r'"([A-Z_0-9]+)":\s*"([^"]*)"', block))


def tool_used(x, t):
    if x == "import":                       # ImageMagick's `import` vs Python's import statement: only count it when it is a quoted command word
        return bool(re.search(r"[\"']import[\"']", t))
    return bool(re.search(rf"(?<![\w./-]){re.escape(x)}(?![\w-])", t))


def script_path(name):
    return EXTRA_FILES.get(name) or (SD / name)


def facts(name, keys):
    p = script_path(name)
    t = read(p)
    used = sorted(k for k in keys if re.search(rf"(?<![A-Z_]){k}\b", t))
    used += [k for k in ("NIGHT_GAMMA", "NIGHTLIGHT_TINT") if re.search(rf"\b{k}\b", t) and k not in used]
    tools = sorted({x for x in TOOLS if tool_used(x, t) and x != "python3"})
    paths = set()
    for m in re.finditer(r"(\$XDG_RUNTIME_DIR|\$\{XDG_RUNTIME_DIR[^}]*\}|\$RT|\$XDG_STATE_HOME|\$\{XDG_STATE_HOME[^}]*\}|\$HOME|~)/[A-Za-z0-9_.\-/]+", t):
        s = m.group(0)
        if "/.config/scripts" in s or s.endswith("/") or s.endswith(".sh") and "scripts" in s:
            continue
        paths.add(s.replace("${XDG_RUNTIME_DIR:-/tmp}", "$XDG_RUNTIME_DIR").replace("$HOME", "~"))
    for m in re.finditer(r"/(?:sys|proc|usr/share|var/lib|var/backups|etc)/[A-Za-z0-9_.\-/*]+", t):
        paths.add(m.group(0))
    calls = sorted({o for o in [x.name for x in SD.glob("*")] + ["autorotate.sh"] if o != name and o in t and not o.endswith(".bak")})
    root = bool(re.search(r"\bsudo\b|pkexec", t)) and name != "lag-now"
    return dict(keys=used, tools=tools, paths=sorted(paths)[:14], calls=calls, root=root, lines=len(t.splitlines()))


def card(name, keys):
    p = script_path(name)
    f = facts(name, keys)
    hdr = py_docstring_or_header(str(p)) if str(p).endswith(".py") else header_block(str(p))
    rel = str(p.relative_to(DOTS))
    out = [f"### `{name}`\n", f"`{rel}` · {f['lines']} lines · needs root: **{'yes (it calls sudo itself)' if f['root'] else 'no'}**\n"]
    if name in PROSE:
        out.append(PROSE[name].strip() + "\n")
    if hdr:
        out.append("**Header comment in the script**\n\n```text\n" + "\n".join(hdr[:30]) + "\n```\n")
    rows = []
    if f["keys"]:
        rows.append(("Settings it reads (`settings.env`)", ", ".join(f"`{k}`" for k in f["keys"])))
    if f["calls"]:
        rows.append(("Other scripts it calls", ", ".join(f"`{c}`" for c in f["calls"])))
    if f["tools"]:
        rows.append(("Programs it uses", ", ".join(f"`{t}`" for t in f["tools"])))
    if f["paths"]:
        rows.append(("Files and paths it touches", ", ".join(f"`{x}`" for x in f["paths"])))
    if rows:
        out.append(table(["Fact (extracted from the script)", "Value"], rows))
    return "\n".join(out)


def build():
    keys = settings_keys()
    for slug, (title, order, names, intro) in GROUPS.items():
        names = list(names) + (SESSION_EXTRA if slug == "session" else [])
        body = [intro + "\n\nEach script has a short explanation, then a block of **facts that are extracted from the script itself** (settings it reads, programs it calls, files it touches), "
                "so the list stays honest when the script changes. Scripts live in `~/.config/scripts` (the repo's `scripts/` folder); `install.sh` copies them there.\n", TOC]
        body.append("\n## Scripts on this page\n\n" + "\n".join(f"- [`{n}`](#{n.replace('.', '').lower()})" for n in names) + "\n")
        for n in names:
            body.append("\n" + card(n, keys))
        write(f"scripts/{slug}.md", fm(title, "Scripts", order), f"# {title}\n\n" + "\n".join(body))

    # settings.env reference
    page_of = {}
    txt = read(SD / "settings.py")
    funcs = re.split(r"\n(?:def|class) (\w+)", txt)
    for i in range(1, len(funcs), 2):
        pname, bodytxt = funcs[i], funcs[i + 1]
        if pname == "fan_group":
            pname = "page_power"
        if not pname.startswith("page_"):
            continue
        for k in keys:
            if re.search(rf'"{k}"', bodytxt):
                page_of.setdefault(k, set()).add(pname[5:])
    pretty_page = {"display": "Display", "power": "Power & Performance", "input": "Keyboard & Mouse", "windows": "Windows & Terminal", "bar": "Top Bar", "spotlight": "Spotlight",
                   "general": "General", "wallpaper": "Wallpaper", "backup": "Backup", "battery": "Battery", "sound": "Sound", "startup": "Startup Apps", "system": "System"}
    readers = {}
    for f in sorted(SD.glob("*")):
        if f.is_file() and f.name not in ("settings.py",):
            t = read(f)
            for k in keys:
                if re.search(rf"(?<![A-Z_]){k}\b", t):
                    readers.setdefault(k, []).append(f.name)
    for f in (DOTS / "wallpaper-config/wallpaper-cycle.sh", DOTS / "i3lock/lock.sh"):
        t = read(f)
        for k in list(keys) + ["ACCENT_HEX"]:
            if f.name == "wallpaper-cycle.sh" and k == "NIGHT_START":
                continue                      # a local variable of the same name, not the setting
            if re.search(rf"(?<![A-Z_]){k}\b", t):
                readers.setdefault(k, []).append(f.parent.name + "/" + f.name)
    rows = []
    for k, v in sorted(keys.items()):
        pages = ", ".join(pretty_page.get(x, x) for x in sorted(page_of.get(k, [])))
        rows.append((f"`{k}`", f"`{v}`", pages or "(set by a script)", ", ".join(f"`{x}`" for x in sorted(set(readers.get(k, []))))))
    body = ["`~/.config/rog/settings.env` is one plain file of `KEY=\"value\"` lines. The Settings app writes it (sorted, with a comment header), and every script and helper program **sources or greps it**: there is no daemon holding state. "
            "You can edit it by hand; the Settings app re-reads the file before every write (`setv`), so a change made by `power-mode.sh` meanwhile is not lost.\n\n"
            "`NIGHT_GAMMA` is derived: the app converts `NIGHT_K` (colour temperature) into `R:G:B` gamma factors so the shell scripts need no maths. Older versions stored `AC_PROFILE` / `BAT_PROFILE` and `SETTINGS_DARK`; on load they are migrated "
            "to `MODE_AC` / `MODE_BAT` and `APPEARANCE`, and the old keys are dropped on the next save.\n", TOC,
            f"\n## All {len(keys)} settings\n\nGenerated from the `DEFAULTS` table in `settings.py` and from which scripts mention each key.\n\n",
            table(["Key", "Default", "Where I change it in Settings", "Read by"], rows)]
    body.append("\n## Where the defaults come from\n\nThe table above shows what a fresh install gets. My own `rog/settings.env` in the repo differs slightly (for example a night tint of 2913 K from 20:00 to 06:00 and the dark theme). "
                "Settings → General → *Export settings* saves this file together with Spotlight's `aliases`, `roots` and `sync.list` as one tarball, and *Import settings* restores them and re-applies power, night tint and input.\n")
    write("scripts/settings-reference.md", fm("settings.env reference", "Scripts", 7), "# `settings.env` reference\n\n" + "\n".join(body))

    # scripts index
    allrows = []
    for f in sorted(SD.glob("*")):
        if not f.is_file():
            continue
        hdr = py_docstring_or_header(str(f)) if f.suffix == ".py" else header_block(str(f))
        first = ""
        for l in hdr:
            l2 = re.sub(r"^rog-tune:\s*", "", l.strip())
            if l2 and not l2.startswith("usage"):
                first = l2
                break
        page = next((s for s, (_, _, ns, _) in GROUPS.items() if f.name in ns), "")
        if f.name in ("spotlight.py",):
            link = "[Spotlight](../spotlight/)"
        elif f.name == "settings.py":
            link = "[Settings app](settings-app.html)"
        elif page:
            link = f"[{GROUPS[page][0]}]({page}.html#{f.name.replace('.', '').lower()})"
        else:
            link = ""
        allrows.append((f"`{f.name}`", first[:170], link))
    body = ["Everything in `~/.config/scripts` (the repo's `scripts/` folder). Nearly all of it started as one big installer, `rog-lean-session.sh`, which writes these files out; today the files are the source of truth and the repo keeps them in sync "
            "(see [rog-tune](../rog-tune/)).\n", TOC, "\n## Every script\n\n", table(["Script", "What it does (first line of its header)", "Documented in"], allrows),
            "\n## Other scripts that are documented elsewhere\n\n"
            "| Where | What |\n|---|---|\n"
            "| `i3/toggle-touchpad.sh` | [Session helpers](session.html#toggle-touchpadsh) |\n"
            "| `wallpaper-config/wallpaper-cycle*.sh` | [System tools](system.html#wallpaper-cyclesh) |\n"
            "| `polybar/scripts/*.sh` | [Polybar](../i3/polybar.html) |\n"
            "| `rofi/*.sh`, `rofi/spotlight-v3.py` | the old rofi launcher, kept for reference: [Other app configs](../i3/other-apps.html) |\n"
            "| `rog-tune/*.sh` | [rog-tune](../rog-tune/) |\n"
            "| `iso/*` | [Restore ISO](../iso/) |\n"
            "| `docs/make-screenshots/*` | [How the screenshots are made](../i3/screenshots.html) |\n"]
    write("scripts/index.md", fm("Scripts", None, 4, children=True, desc="All my desktop scripts, explained"), "# Scripts\n\n" + "\n".join(body))
    return keys


if __name__ == "__main__":
    k = build()
    print(len(k), "settings keys")
