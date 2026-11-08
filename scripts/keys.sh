#!/usr/bin/env bash
# rog-tune: show every i3 keybind in a searchable rofi list (type to filter, Esc to close)
cfg=${1:-$HOME/.config/i3/config}
list=$(python3 - "$cfg" <<'PY'
import re, sys
raw = open(sys.argv[1]).read().replace("\\\n", " ")
vars_ = dict(re.findall(r'^\s*set\s+(\$\w+)\s+(.+?)\s*$', raw, re.M))
def pretty(k):
    for a, b in (("$mod", "Super"), ("Mod4", "Super"), ("Mod1", "Alt"), ("Control", "Ctrl")):
        k = k.replace(a, b)
    k = re.sub(r'\$\w+', lambda m: vars_.get(m.group(0), m.group(0)).strip('"'), k)
    for a, b in (("semicolon", ";"), ("slash", "/"), ("Return", "Enter"), ("Escape", "Esc"), ("BackSpace", "Backspace"),
                 ("XF86AudioRaiseVolume", "Volume Up"), ("XF86AudioLowerVolume", "Volume Down"), ("XF86AudioMute", "Mute key"),
                 ("XF86AudioMicMute", "Mic-mute key"), ("XF86MonBrightnessUp", "Brightness Up"), ("XF86MonBrightnessDown", "Brightness Down"),
                 ("XF86KbdBrightnessUp", "Kbd-light Up"), ("XF86KbdBrightnessDown", "Kbd-light Down"), ("XF86TouchpadToggle", "Touchpad key")):
        k = k.replace(a, b)
    return k.replace("+", " + ")
def describe(c):
    c = re.sub(r'^exec(_always)?\s+(--no-startup-id\s+)?', '', c)
    c = re.sub(r'^(sh|bash)( -l?c)?\s+', '', c).strip("\"' ")
    c = c.replace("$HOME/", "~/").replace("~/.config/", "").replace("--no-startup-id ", "")
    c = re.sub(r'\$\w+', lambda m: vars_.get(m.group(0), m.group(0)).strip('"'), c)
    return re.sub(r'\s+', ' ', c)[:90]
out, mode = [], ""
for line in raw.splitlines():
    t = line.strip()
    m = re.match(r'mode\s+"([^"]+)"\s*\{', t)
    if m: mode = "[" + m.group(1) + "] "; continue
    if t == "}": mode = ""; continue
    m = re.match(r'bindsym\s+(?:--\S+\s+)*(\S+)\s+(.+)$', t)
    if m and not t.startswith("#"):
        out.append((mode + pretty(m.group(1)), describe(m.group(2))))
w = max(len(k) for k, _ in out) + 2
print("\n".join(f"{k:<{w}}{d}" for k, d in out))
PY
)
printf '%s\n' "$list" | rofi -dmenu -i -no-custom -p "keys" -theme ~/.config/rofi/catppuccin-mocha.rasi \
	-theme-str 'window { width: 1500px; } listview { lines: 13; } * { font: "JetBrainsMono Nerd Font 20"; }'
