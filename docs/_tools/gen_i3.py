"""Generated pages for the i3 section: keybindings, autostart, window rules. Everything comes from i3/config itself."""
import re
from common import *

CONFIG = DOTS / "i3/config"

# friendly text for commands that are scripts of mine (the raw command is always shown next to it)
NICE = {
    "scripts/shot.sh full": "Screenshot of the whole screen: to the clipboard and ~/Pictures",
    "scripts/shot.sh area": "Screenshot of a selected area: to the clipboard and ~/Pictures",
    "scripts/shot.sh area-clip": "Screenshot of a selected area: clipboard only, no file",
    "scripts/shot.sh window": "Screenshot of the focused window",
    "scripts/ocr.sh": "Select an area; the text in it goes to the clipboard (OCR)",
    "scripts/keys.sh": "Searchable list of every keybinding (rofi)",
    "scripts/nightlight.sh toggle": "Night tint on/off",
    "scripts/nightlight.sh auto": "Night tint back to the schedule",
    "scripts/sysmon.sh": "GUI task monitor",
    "scripts/autorotate.sh lock": "Freeze/unfreeze automatic screen rotation",
    "scripts/rog-ui.sh spotlight": "Spotlight (toggle)",
    "scripts/rog-ui.sh settings": "Settings app",
    "scripts/rog-ui.sh clip": "Spotlight in clipboard-history mode",
    "scripts/caffeine.sh toggle": "Caffeine: keep the screen on and unlocked",
    "scripts/tablet.sh toggle": "Tablet mode (on-screen keyboard)",
    "scripts/pin.sh": "Pin the window (floating, sticky, always visible) or put it back",
    "scripts/power-mode.sh cycle": "Cycle performance mode Quiet → Balanced → Performance",
    "scripts/osd.sh vol up": "Volume +5 %",
    "scripts/osd.sh vol down": "Volume -5 %",
    "scripts/osd.sh vol mute": "Mute/unmute the speakers",
    "scripts/osd.sh mic": "Mute/unmute the microphone",
    "scripts/osd.sh bri up": "Brightness +5 %",
    "scripts/osd.sh bri down": "Brightness -5 %",
    "scripts/scratch.sh": "Scratchpad: floating Neovim on ~/Documents/scratch.md (toggle)",
    "scripts/power-menu.py": "Power menu",
    "i3lock/lock.sh": "Lock the screen",
    "i3/toggle-touchpad.sh": "Touchpad on/off",
    "wallpaper-config/wallpaper-cycle.sh": "Next wallpaper",
    "wallpaper-config/wallpaper-cycle-reverse.sh": "Previous wallpaper",
    "local/bin/lag-now": "Lag snapshot: appends to ~/lag-notes.log",
    "polybar-msg cmd toggle": "Show/hide the bar",
    "rofi -show window": "Window switcher (rofi)",
    "i3-sensible-terminal": "Terminal (the default one)",
    "kitty": "kitty terminal",
    "asusctl aura power keyboard --boot --awake --sleep": "Keyboard backlight on (all states)",
    "asusctl aura power keyboard": "Keyboard backlight (default)",
}


EXEC_WHY = [
    ("systemctl --user import-environment", "Hands DISPLAY, the D-Bus address and friends to systemd user services, so they can talk to my session"),
    ("dbus-update-activation-environment", "Same for D-Bus-activated programs (portals, notification daemons)"),
    ("export XDG_CURRENT_DESKTOP=i3", "Tells portals and apps they are running under i3"),
    ("picom --config", "The compositor: translucency and blur (config is a symlink, see Compositor page)"),
    ("polybar -c", "The bar. Kills any running copy first so a reload never leaves two bars"),
    ("wallpaper-cycle.sh", "Sets the wallpaper (day/night folders) once per login; a reload keeps the current one"),
    ("autorotate.sh", "Follows the accelerometer: rotates the panel, touchscreen and pen together"),
    ("pen-setup.sh", "Maps the ASUS stylus and touchscreen to the internal panel and sets pen buttons"),
    ("Natural Scrolling Enabled", "Natural scrolling on the touchpad (the Settings app later overrides this through input-apply.sh)"),
    ("Tapping Button Mapping Enabled", "Tap to click: one finger = left, two fingers = right"),
    ("xsetroot -cursor_name", "Normal arrow cursor on the empty desktop"),
    ("power-watch.sh", "Watches the power source (upower) and applies performance mode, refresh rate, lock timers and the compositor variant"),
    ("nightlight.sh daemon", "Applies the night tint on schedule (wakes every 5 minutes or when told)"),
    ("xss-lock", "Runs the lock screen when the idle timer fires and before suspend"),
    ("autocaffeine.sh", "Keeps the screen on while something is fullscreen or the microphone is in use"),
    ("rog-ui.sh start", "Starts the resident Spotlight process so Super+D is instant"),
    ("input-apply.sh", "Applies touchpad, pointer and key-repeat settings from the Settings app"),
    ("login-apply.sh", "Once per login: optional muted mic, restore the brightness I last chose"),
    ("display-agent.py", "Adaptive refresh rate, cinema mode, camera-in-use flag and optional workspace icons"),
    ("wallpaper-timer.sh", "Re-creates the optional automatic wallpaper timer from Settings"),
]


def exec_why(cmd, fallback):
    for k, v in EXEC_WHY:
        if k in cmd:
            return v
    return fallback


def pretty_key(k, vars_):
    for a, b in (("$mod", "Super"), ("Mod4", "Super"), ("Mod1", "Alt"), ("Control", "Ctrl")):
        k = k.replace(a, b)
    k = re.sub(r"\$\w+", lambda m: vars_.get(m.group(0), m.group(0)).strip('"'), k)
    for a, b in (("semicolon", ";"), ("slash", "/"), ("comma", ","), ("Return", "Enter"), ("Escape", "Esc"), ("BackSpace", "Backspace"),
                 ("XF86AudioRaiseVolume", "Volume Up"), ("XF86AudioLowerVolume", "Volume Down"), ("XF86AudioMute", "Mute key"),
                 ("XF86AudioMicMute", "Mic-mute key"), ("XF86MonBrightnessUp", "Brightness Up"), ("XF86MonBrightnessDown", "Brightness Down"),
                 ("XF86KbdBrightnessUp", "Keyboard-light Up"), ("XF86KbdBrightnessDown", "Keyboard-light Down"), ("XF86TouchpadToggle", "Touchpad key")):
        k = k.replace(a, b)
    return k.replace("+", " + ")


def describe(cmd, vars_):
    c = re.sub(r"^exec(_always)?\s+(--no-startup-id\s+)?", "", cmd)
    raw = c
    c2 = c.replace("$HOME/", "").replace("~/", "").replace(".config/", "").strip("\"' ")
    for k, v in sorted(NICE.items(), key=lambda kv: -len(kv[0])):
        if c2.endswith(k) or c2 == k or k in c2:
            return v, raw
    m = re.match(r"^workspace number \$ws(\d+)", cmd)
    if m:
        return f"Go to workspace {m.group(1)}", raw
    m = re.match(r"^move container to workspace number \$ws(\d+)", cmd)
    if m:
        return f"Send the window to workspace {m.group(1)}", raw
    simple = {"focus left": "Focus left", "focus right": "Focus right", "focus up": "Focus up", "focus down": "Focus down",
              "move left": "Move window left", "move right": "Move window right", "move up": "Move window up", "move down": "Move window down",
              "split v": "Next window opens below (split vertically)", "fullscreen toggle": "Fullscreen",
              "layout stacking": "Layout: stacked", "layout tabbed": "Layout: tabbed", "layout toggle split": "Layout: toggle split direction",
              "floating toggle": "Floating on/off", "focus mode_toggle": "Focus: floating ⇄ tiled", "focus parent": "Focus the parent container",
              "kill": "Close the window", "reload": "Reload the i3 config", "restart": "Restart i3 in place",
              "mode \"resize\"": "Enter resize mode", "mode \"default\"": "Leave resize mode", "workspace prev": "Previous workspace",
              "workspace next": "Next workspace", "move container to workspace prev; workspace prev": "Send the window to the previous workspace and follow it",
              "move container to workspace next; workspace next": "Send the window to the next workspace and follow it"}
    if cmd in simple:
        return simple[cmd], raw
    if cmd.startswith("resize"):
        return cmd.replace("resize shrink ", "Shrink the window's ").replace("resize grow ", "Grow the window's ").replace(" 10 px or 10 ppt", " by 10 px (or 10 %)"), raw
    if cmd.startswith("exec \"i3-nagbar"):
        return "Exit i3 (asks first)", raw
    return c2[:80], raw


def category(cmd, key):
    if key.startswith("XF86") or "Volume" in key or "Brightness" in key or "Mute" in key or "Touchpad" in key or "light" in key:
        return "Hardware keys"
    if "workspace" in cmd:
        return "Workspaces"
    if re.match(r"^(focus|move |kill)", cmd):
        return "Windows: focus, move, close"
    if re.match(r"^(split|layout|fullscreen|floating|resize|sticky)", cmd) or "pin.sh" in cmd or cmd.startswith("mode"):
        return "Windows: layout and size"
    if "shot.sh" in cmd or "ocr.sh" in cmd:
        return "Screenshots and OCR"
    if any(x in cmd for x in ("rog-ui.sh", "kitty", "i3-sensible-terminal", "rofi", "keys.sh", "scratch.sh", "sysmon.sh", "polybar-msg")):
        return "Launching things"
    if any(x in cmd for x in ("lock.sh", "power-menu", "nagbar", "reload", "restart", "lag-now")):
        return "Session"
    if any(x in cmd for x in ("nightlight", "caffeine", "power-mode", "tablet", "autorotate", "wallpaper")):
        return "Display, power and comfort"
    return "Other"


def parse():
    raw = read(CONFIG).replace("\\\n", " ")
    vars_ = dict(re.findall(r"^\s*set\s+(\$\w+)\s+(.+?)\s*$", raw, re.M))
    binds, execs, rules, mode = [], [], [], ""
    last_comment = ""
    for line in raw.splitlines():
        t = line.strip()
        if t.startswith("#"):
            if not t.startswith("# bindsym") and not t.startswith("# exec") and not t.startswith("# rog-tune: exec") and not t.startswith("# rog-tune: bindsym"):
                last_comment = re.sub(r"^#\s*(rog-tune:\s*)?", "", t)
            continue
        m = re.match(r'mode\s+"([^"]+)"\s*\{', t)
        if m:
            mode = m.group(1)
            continue
        if t == "}":
            mode = ""
            continue
        m = re.match(r"bindsym\s+(?:--\S+\s+)*(\S+)\s+(.+)$", t)
        if m:
            key, cmd = m.group(1), m.group(2)
            nice, rawcmd = describe(cmd, vars_)
            binds.append(dict(mode=mode, key=pretty_key(key, vars_), cmd=rawcmd, desc=nice, cat="Resize mode" if mode else category(cmd, key), note=last_comment))
            continue
        m = re.match(r"(exec_always|exec)\s+(.+)$", t)
        if m:
            execs.append((m.group(1), m.group(2), last_comment))
            continue
        m = re.match(r"for_window\s+(\[[^\]]+\])\s+(.+)$", t)
        if m:
            rules.append((m.group(1), m.group(2), last_comment))
    return binds, execs, rules, vars_


def build():
    binds, execs, rules, vars_ = parse()
    order = ["Launching things", "Windows: focus, move, close", "Windows: layout and size", "Workspaces", "Screenshots and OCR",
             "Display, power and comfort", "Hardware keys", "Session", "Resize mode", "Other"]
    body = ["Every row here is generated from my real `i3/config` (the `bindsym` lines), so this page cannot drift from what the keys really do. "
            "`Super` is the Windows key, which on my keyboards is also Caps Lock (see [Troubleshooting](troubleshooting.html)). "
            "You do not have to remember any of this: **Super+F1** or **Super+/** opens the same list as a searchable menu "
            "([`keys.sh`](../scripts/session.html#keyssh)).\n", TOC]
    for cat in order:
        rows = [b for b in binds if b["cat"] == cat]
        if not rows:
            continue
        body.append(f"\n## {cat}\n")
        body.append(table(["Key", "What it does", "Command in the config"], [(f"`{b['key']}`", b["desc"], f"`{b['cmd']}`") for b in rows]))
    body.append("\n## Mouse\n")
    body.append("These come from `floating_modifier` and `tiling_drag` in the config:\n\n"
                + table(["Gesture", "What it does"], [("Super + left-drag", "Move a floating window"), ("Super + right-drag", "Resize a floating window"),
                                                       ("Drag a window's title bar", "Move a tiled window (`tiling_drag modifier titlebar`)"),
                                                       ("Focus follows mouse", "The window under the pointer gets focus without a click (`focus_follows_mouse yes`)")]))
    body.append(f"\n## Counts\n\n{len(binds)} bindings in total ({sum(1 for b in binds if b['mode'])} of them in resize mode).\n")
    write("i3/keybindings.md", fm("Keybindings", "i3 desktop", 3, desc="Every i3 keybinding, generated from the config"), "# Keybindings\n\n" + "\n".join(body))

    # autostart
    rows = []
    for kind, cmd, note in execs:
        cmd_s = cmd.replace("--no-startup-id ", "")
        short = cmd_s.replace("$HOME/", "~/").replace("/home/sarang/", "~/")
        short = re.sub(r"\s+#.*$", "", short)
        rows.append(("once at login" if kind == "exec" else "every start and reload", f"`{short}`", exec_why(cmd_s, note)))
    body = ["Everything below is an `exec` or `exec_always` line in `i3/config`. **`exec`** runs once when i3 starts; **`exec_always`** runs again on every "
            "reload (`Super+Shift+C`) and restart (`Super+Shift+R`), which is why those scripts all kill their previous copy first (see "
            "[Script conventions](../scripts/conventions.html)).\n\nThe last column says what each line is for.\n", TOC,
            "\n## The lines\n", table(["When", "Command", "What it is for"], rows),
            "\n## What else starts at login\n\n"
            "- `xss-lock --transfer-sleep-lock -- ~/.config/i3lock/lock.sh` (the `exec` line marked *idle*): locks the screen when the idle timer fires and before suspend. "
            "See [Lock screen](lock-screen.html).\n"
            "- The **resident Spotlight process** is started by `rog-ui.sh start`, so it is already in memory when I press Super+D. See [Spotlight internals](../spotlight/internals.html).\n"
            "- **XDG autostart** entries: the repo's `autostart/` folder holds four `.desktop` stubs that switch things off (`picom`, `nm-applet`, GNOME's disk-notify daemon, the AT-SPI bus). "
            "They are `Hidden=true` copies that override the system entries in `/etc/xdg/autostart`; the Settings app's *Startup Apps* page edits the same kind of file.\n"
            "- **Greeter and root-side services** are not part of i3 at all; they are in [rog-tune](../rog-tune/).\n"]
    write("i3/autostart.md", fm("Autostart and session", "i3 desktop", 4), "# Autostart and session\n\n" + "\n".join(body))

    # window rules
    rrows = [(f"`{c}`", f"`{a}`", note) for c, a, note in rules]
    scalar = []
    raw = read(CONFIG)
    for key in ("default_border", "default_floating_border", "hide_edge_borders", "focus_follows_mouse", "workspace_auto_back_and_forth", "floating_modifier",
                "tiling_drag", "font"):
        m = re.search(rf"^{key}\s+(.+)$", raw, re.M)
        if m:
            scalar.append((f"`{key}`", f"`{m.group(1).strip()}`"))
    colours = re.findall(r"^(client\.\w+)\s+(.+)$", raw, re.M)
    body = ["This page lists the window rules and the look-and-behaviour settings from `i3/config`. The rules are generated from the file.\n", TOC,
            "\n## Window rules (`for_window`)\n\nA rule is `[criteria] commands`: when a window appears and matches the criteria, i3 runs the commands on it. "
            "Most of mine make my own helper windows (Spotlight, the power menu, the alarm, the scratchpad) float and centre themselves, and keep "
            "dialogs from tiling.\n\n", table(["Matches", "i3 does", "Why (comment in the config)"], rrows),
            "\n## Behaviour and look\n\n", table(["Setting", "Value"], scalar),
            "\n### Colours\n\nThe `client.*` lines paint the window borders (border, background, text, indicator, child border). The amber on `client.focused` is my "
            "accent colour; the accent script rewrites it, see [Colours, accent and fonts](theme.html).\n\n",
            table(["Class", "Border / background / text / indicator / child border"], [(f"`{a}`", f"`{b}`") for a, b in colours]),
            "\n## Workspaces\n\n"
            "Ten workspaces, named `1`…`10` through `set $ws1 \"1\"` and so on. Every binding uses `workspace number N`, so the *names* can change without breaking the keys: "
            "the display agent can rename them to include app icons (Settings → Top Bar → *Show app icons next to the numbers*), and `workspace_auto_back_and_forth yes` "
            "means pressing the number of the workspace you are already on jumps back to the previous one.\n\n"
            "## Layout cheat-sheet\n\n"
            "i3 is a tree of containers. `Super+V` says \"the next window goes *below* this one\", `Super+E` toggles the split direction, `Super+S` stacks, `Super+W` makes tabs, "
            "`Super+A` focuses the parent container so a layout command can apply to a whole group, `Super+F` is fullscreen, `Super+Shift+Space` floats, and "
            "`Super+R` enters resize mode (h/j/k/l or arrows, Enter or Esc to leave). The pictures in the [README](https://github.com/sarang-kernel/i3-dotfiles) show tabbed and stacked.\n"]
    write("i3/windows.md", fm("Windows, workspaces and rules", "i3 desktop", 5), "# Windows, workspaces and rules\n\n" + "\n".join(body))
    return binds, execs, rules


if __name__ == "__main__":
    b, e, r = build()
    print(len(b), "binds", len(e), "execs", len(r), "rules")
