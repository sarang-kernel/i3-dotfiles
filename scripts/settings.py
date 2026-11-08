#!/usr/bin/env python3
# rog-tune: Settings, in the style of GNOME Settings (GTK4 + libadwaita): a category sidebar, grouped rows, changes apply at once.
#   settings.py            the settings window (starts on demand, nothing stays in memory afterwards)
#   settings.py --backup   choose what to back up, then run the backup (also: Spotlight -> "Back up to hp-server…")
import json, math, os, re, shutil, subprocess, sys, tarfile, threading, time
from pathlib import Path
import gi
gi.require_version("Gtk", "4.0"); gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw, Gdk, Gio, GLib

HOME = Path.home()
CONF = HOME / ".config/rog"; CONF.mkdir(parents=True, exist_ok=True)
ENV = CONF / "settings.env"
SD = HOME / ".config/scripts"
STATE = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state"))
DEFAULTS = {"NIGHT_K": "4000", "NIGHT_START": "19", "NIGHT_END": "7", "LOCK_AC": "10", "OFF_AC": "15", "LOCK_BAT": "2", "OFF_BAT": "3",
            "MODE_AC": "balanced", "MODE_BAT": "quiet", "AUTOCAFFEINE": "1", "SPOT_RECENTS": "1", "SPOT_OPACITY": "62",
            "RATE_AC": "90", "RATE_BAT": "60", "TP_TAP": "1", "TP_NATURAL": "0", "TP_DWT": "1", "PTR_SPEED": "0",
            "KEY_DELAY": "250", "KEY_RATE": "50", "MIC_MUTE_LOGIN": "0", "SHOT_SAVE": "1", "BACKUP_MIRROR": "0", "APPEARANCE": "light", "ACCENT_MODE": "amber", "ACCENT_HEX": "#c47f1c", "WS_ICONS": "0",
            "AUTOQUIET": "1", "AUTOQUIET_PCT": "20", "ALARM_SOUND": "1",
            "ADAPTIVE": "1", "ADAPTIVE_IDLE_S": "60", "IDLE_HZ": "60", "CINEMA": "1", "CINEMA_HZ": "71.928",
            "WALL_DAY_START": "7", "WALL_NIGHT_START": "19", "WALL_EVERY": "0", "FAN_CURVE": "default"}
FILM_RATES = [("71.928", "71.93 Hz (23.976 fps films, exact)"), ("72", "72 Hz (24 fps films)"), ("96", "96 Hz (24 fps, 4 to 1)"), ("120", "120 Hz (24 and 30 fps)"),
              ("75", "75 Hz (25 fps)"), ("100", "100 Hz (25 fps, 4 to 1)")]
# every rate the panel can do: the native 60 and 165 Hz modes, and any rate in between (the panel is variable-refresh 58-165 Hz and
# takes the same timings at any pixel clock, which is how power-watch.sh makes the rest)
RATES = [60, 70, 72, 75, 80, 85, 90, 96, 100, 110, 120, 125, 130, 140, 144, 150, 155, 160, 165]
BAR_MODULES = [("pulseaudio", "Volume"), ("brightness", "Brightness"), ("battery", "Battery"), ("memory", "Memory"),
               ("cpu", "CPU"), ("network", "Wi-Fi"), ("mic", "Microphone"), ("camera", "Camera in use (only shows while a camera is open)")]
CANDIDATES = ["notes", "Documents", "Desktop", "Pictures", "Downloads", "Development", "Music", "Videos", "Zotero", ".ssh", ".config"]

# ---------------------------------------------------------------- state
def load():
    d = dict(DEFAULTS); raw = {}
    try:
        for l in ENV.read_text().splitlines():
            if "=" in l and not l.startswith("#"):
                k, v = l.split("=", 1); raw[k.strip()] = v.strip().strip('"')
    except Exception:
        pass
    d.update({k: v for k, v in raw.items() if k in DEFAULTS or k == "NIGHT_GAMMA"})
    # older versions stored CPU profiles; carry them over once
    if "MODE_AC" not in raw and raw.get("AC_PROFILE") == "performance": d["MODE_AC"] = "performance"
    if "MODE_BAT" not in raw and raw.get("BAT_PROFILE") in ("balanced", "performance"): d["MODE_BAT"] = raw["BAT_PROFILE"]
    if "APPEARANCE" not in raw and raw.get("SETTINGS_DARK") == "1": d["APPEARANCE"] = "dark"
    return d

def gamma_for(k):
    t = k / 100.0
    r = 255 if t <= 66 else max(0, min(255, 329.698727446 * ((t - 60) ** -0.1332047592)))
    g = 99.4708025861 * math.log(t) - 161.1195681661 if t <= 66 else 288.1221695283 * ((t - 60) ** -0.0755148492)
    b = 255 if t >= 66 else (0 if t <= 19 else 138.5177312231 * math.log(t - 10) - 305.0447927307)
    c = lambda x: max(0.0, min(255.0, x)) / 255.0
    return f"{c(r):.2f}:{c(g):.2f}:{c(b):.2f}"

def save(d):
    d["NIGHT_GAMMA"] = gamma_for(int(d["NIGHT_K"]))        # derived, so the shell scripts need no maths
    for k in ("AC_PROFILE", "BAT_PROFILE"): d.pop(k, None)
    ENV.write_text("# written by settings.py; sourced by the scripts in ~/.config/scripts\n" + "".join(f'{k}="{v}"\n' for k, v in sorted(d.items())))

def setv(k, v):
    d = load(); d[k] = str(v); save(d)                       # re-read first: power-mode.sh may have changed the file meanwhile

def run(*cmd):
    try: return subprocess.run(list(cmd), capture_output=True, text=True, timeout=8).stdout.strip()
    except Exception: return ""

def bg(*cmd):
    subprocess.Popen(list(cmd), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, stdin=subprocess.DEVNULL, start_new_session=True)

def read_list(path, default):
    try:
        r = [os.path.expanduser(l.strip()) for l in Path(path).read_text().splitlines() if l.strip() and not l.startswith("#")]
        return r if r else default
    except Exception:
        return default

# ---------------------------------------------------------------- row helpers
def switch_row(title, sub, active, cb):
    r = Adw.SwitchRow(title=title, subtitle=sub or ""); r.set_active(active)
    r.connect("notify::active", lambda w, p: cb(w.get_active())); return r

def combo_row(title, sub, options, current, cb):
    r = Adw.ComboRow(title=title, subtitle=sub or ""); keys = [k for k, _ in options]
    r.set_model(Gtk.StringList.new([l for _, l in options]))
    if current in keys: r.set_selected(keys.index(current))
    r.connect("notify::selected", lambda w, p: cb(keys[w.get_selected()])); return r

def spin_row(title, sub, lo, hi, val, cb, step=1):
    r = Adw.SpinRow.new_with_range(lo, hi, step); r.set_title(title); r.set_subtitle(sub or ""); r.set_value(val)
    r.connect("notify::value", lambda w, p: cb(int(w.get_value()))); return r

def scale_row(title, sub, lo, hi, step, val, fmt, cb):
    r = Adw.ActionRow(title=title, subtitle=sub or "")
    sc = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, lo, hi, step); sc.set_value(val); sc.set_size_request(380, -1)
    sc.set_draw_value(True); sc.set_value_pos(Gtk.PositionType.RIGHT); sc.set_valign(Gtk.Align.CENTER)
    if fmt: sc.set_format_value_func(lambda s, v: fmt(v))
    pending = [0]
    def changed(w):                                           # apply once the slider rests, not on every pixel
        if pending[0]: GLib.source_remove(pending[0])
        pending[0] = GLib.timeout_add(350, lambda: (cb(w.get_value()), pending.__setitem__(0, 0), False)[2])
    sc.connect("value-changed", changed); r.add_suffix(sc); return r

def button_row(title, sub, label, cb, suggested=False):
    r = Adw.ActionRow(title=title, subtitle=sub or ""); b = Gtk.Button(label=label); b.set_valign(Gtk.Align.CENTER)
    if suggested: b.add_css_class("suggested-action")
    b.connect("clicked", lambda _: cb()); r.add_suffix(b); r.set_activatable_widget(b); return r

def group(title, rows, desc=None):
    g = Adw.PreferencesGroup(title=title or "")
    if desc: g.set_description(desc)
    for r in rows: g.add(r)
    return g

# ---------------------------------------------------------------- folder checklist (backup, deep search)
class FolderDialog(Adw.Window):
    def __init__(self, parent, title, selected, buttons, callback):
        super().__init__(title=title, modal=True, default_width=520, default_height=560)
        if parent: self.set_transient_for(parent)
        self.callback = callback; self.rows = {}
        tv = Adw.ToolbarView(); self.set_content(tv)
        hb = Adw.HeaderBar(); hb.set_show_end_title_buttons(False); hb.set_show_start_title_buttons(False); tv.add_top_bar(hb)
        c = Gtk.Button(label="Cancel"); c.connect("clicked", lambda _: self.finish(None)); hb.pack_start(c)
        for key, label, suggested in reversed(buttons):
            b = Gtk.Button(label=label)
            if suggested: b.add_css_class("suggested-action")
            b.connect("clicked", lambda _, k=key: self.finish(k)); hb.pack_end(b)
        page = Adw.PreferencesPage(); tv.set_content(page)
        self.grp = Adw.PreferencesGroup(title="Folders"); page.add(self.grp)
        names = [str(HOME / c) for c in CANDIDATES if os.path.isdir(HOME / c)]
        for p in selected:
            if p not in names: names.append(p)
        for p in names: self.add_folder(p, p in selected)
        addg = Adw.PreferencesGroup(); page.add(addg)
        addg.add(button_row("Add another folder", None, "Choose…", self.pick))
        k = Gtk.EventControllerKey(); k.connect("key-pressed", lambda c_, kv, kc, st: self.finish(None) if kv == Gdk.KEY_Escape else False); self.add_controller(k)

    def add_folder(self, p, on):
        row = Adw.ActionRow(title=p.replace(str(HOME), "~")); chk = Gtk.CheckButton(); chk.set_active(on); chk.set_valign(Gtk.Align.CENTER)
        row.add_prefix(chk); row.set_activatable_widget(chk); self.grp.add(row); self.rows[p] = chk

    def pick(self):
        fd = Gtk.FileDialog(title="Choose a folder"); fd.set_initial_folder(Gio.File.new_for_path(str(HOME)))
        def done(d, res):
            try:
                f = d.select_folder_finish(res)
                if f and f.get_path() not in self.rows: self.add_folder(f.get_path(), True)
            except GLib.Error: pass
        fd.select_folder(self, None, done)

    def finish(self, key):
        chosen = [p for p, c in self.rows.items() if c.get_active()]
        self.close(); self.callback(key, chosen)

def backup_flow(parent, on_done=None):
    lst = HOME / ".config/spotlight/sync.list"
    sel = read_list(lst, [str(HOME / "notes"), str(HOME / "Documents")])
    def cb(key, chosen):
        if key in ("save", "go"):
            lst.parent.mkdir(parents=True, exist_ok=True)
            lst.write_text("# folders copied by sync-server.sh (edit here, or use Settings)\n" + "\n".join(chosen) + "\n")
        if key == "go" and chosen: bg("kitty", "--class", "rog-sync", str(SD / "sync-server.sh"))
        if on_done: on_done()
    FolderDialog(parent, "Back up to hp-server (external drive)", sel, [("save", "Save only", False), ("go", "Back up now", True)], cb).present()

def deep_roots_dialog(parent):
    f = HOME / ".config/spotlight/roots"
    sel = read_list(f, [str(HOME / "notes"), str(HOME / "Documents")])
    def cb(key, chosen):
        if key == "save":
            f.parent.mkdir(parents=True, exist_ok=True)
            f.write_text("# folders searched by Spotlight's deep search\n" + "\n".join(chosen) + "\n")
    FolderDialog(parent, "Deep search folders", sel, [("save", "Save", True)], cb).present()

# ---------------------------------------------------------------- the pages
def i3_edit(pat, repl):
    f = HOME / ".config/i3/config"; t = f.read_text(); t2 = re.sub(pat, repl, t, flags=re.M)
    if t2 != t: f.write_text(t2)
    bg("i3-msg", "reload")

def picom_edit(pattern, repl):
    f = HOME / ".config/picom/picom-ac.conf"
    t = f.read_text(); t2 = re.sub(pattern, repl, t, flags=re.M)
    if t2 != t: f.write_text(t2)
    pid = run("pgrep", "-xo", "-u", str(os.getuid()), "picom")
    if pid: os.kill(int(pid), 10)                              # SIGUSR1: reload

def page_display(cfg):
    pc = HOME / ".config/picom/picom-ac.conf"; txt = pc.read_text() if pc.exists() else ""
    try: mode = (STATE / "nightlight/mode").read_text().strip() or "auto"
    except Exception: mode = "auto"
    def night_k(k): setv("NIGHT_K", int(k)); bg(str(SD / "nightlight.sh"), "reapply")
    def night_h(key, v): setv(key, v); bg(str(SD / "nightlight.sh"), "reapply")
    def disp(k, v): setv(k, v); bg(str(SD / "power-watch.sh"), "display")
    hz = [(str(r), f"{r} Hz" + (" (native max)" if r == 165 else " (native)" if r == 60 else "")) for r in RATES]
    return [
        group("Night tint", [
            combo_row("Mode", "Automatic follows the schedule below", [("auto", "Automatic"), ("on", "Always on"), ("off", "Off")],
                      mode if mode in ("auto", "on", "off") else "auto", lambda m: bg(str(SD / "nightlight.sh"), m)),
            scale_row("Warmth", "Lower is warmer", 2700, 6000, 100, int(cfg["NIGHT_K"]), lambda v: f"{int(v)} K", night_k),
            spin_row("Automatic: from (hour)", "24 hour clock; the tint is on from this hour…", 0, 23, int(cfg["NIGHT_START"]), lambda v: night_h("NIGHT_START", v)),
            spin_row("Automatic: until (hour)", "…until this hour.", 0, 23, int(cfg["NIGHT_END"]), lambda v: night_h("NIGHT_END", v))]),
        group("Refresh rate", [
            combo_row("On AC power", None, hz, cfg["RATE_AC"], lambda v: disp("RATE_AC", v)),
            combo_row("On battery", "Applied the moment you unplug", hz, cfg["RATE_BAT"], lambda v: disp("RATE_BAT", v))],
            desc="The panel is variable-refresh (58 to 165 Hz), so any rate from 60 to 165 Hz works. Higher is smoother, lower saves power. Quiet mode always uses 60 Hz, whatever is chosen here."),
        group("Adaptive refresh", [
            switch_row("Lower the rate when idle", "After a while without keys or touch the panel drops to the idle rate; the first key or touch brings your rate back "
                       "(the screen blinks briefly as it switches). Only from 110 Hz up. Not in Quiet mode, while audio plays, or in a call.",
                       cfg["ADAPTIVE"] == "1", lambda on: (setv("ADAPTIVE", "1" if on else "0"), bg(str(SD / "power-watch.sh"), "refresh"))),
            spin_row("Idle after (seconds)", "Longer means fewer blinks while you read; shorter saves more", 15, 600, int(cfg["ADAPTIVE_IDLE_S"]), lambda v: setv("ADAPTIVE_IDLE_S", v), 5),
            combo_row("Idle rate", None, [(str(r), f"{r} Hz") for r in RATES if r <= 100], cfg["IDLE_HZ"], lambda v: setv("IDLE_HZ", v))],
              desc="Measured on this laptop, on battery: 60 Hz and 90 Hz draw the same; 120 Hz draws about 0.4 W more and 165 Hz about 0.5 W more. So this only acts when your rate is 110 Hz or higher. At 90 Hz or below it does nothing and never blinks."),
        group("Cinema mode", [
            switch_row("Match the panel to films", "A fullscreen video player (mpv, VLC, Celluloid and similar; not browsers) switches the panel to the film rate below, "
                       "so frames are shown for an equal time and motion is smooth. It switches back when you leave fullscreen.",
                       cfg["CINEMA"] == "1", lambda on: setv("CINEMA", "1" if on else "0")),
            combo_row("Film rate", "Pick the one that divides your films' frame rate evenly", FILM_RATES, cfg["CINEMA_HZ"], lambda v: setv("CINEMA_HZ", v))],
              desc="Exact matching to each video's own frame rate needs mpv's control socket and is not built yet."),
        group("Effects", [
            switch_row("Blur on AC power", "Frosted glass behind terminals; off on battery and in Quiet mode", "blur-background = true" in txt,
                       lambda on: picom_edit(r"^blur-background = (true|false);", f"blur-background = {'true' if on else 'false'};")),
            switch_row("Dim inactive windows", "The window you are not typing in recedes slightly (AC power only).", re.search(r"^inactive-dim\s*=\s*0\.[1-9]", txt, re.M) is not None,
                       lambda on: picom_edit(r"^inactive-dim = [0-9.]+;", f"inactive-dim = {'0.10' if on else '0.0'};"))])]

def page_power(cfg):
    modes = [("quiet", "Quiet"), ("balanced", "Balanced"), ("performance", "Performance")]
    def disp(k, v): setv(k, v); bg(str(SD / "power-watch.sh"), "display")
    def timers(k, v): setv(k, v); bg(str(SD / "power-watch.sh"), "timers")
    def autocaf(on): setv("AUTOCAFFEINE", "1" if on else "0"); bg(str(SD / "autocaffeine.sh"))
    res = [
        group("Performance mode", [
            combo_row("On AC power", "Used while plugged in", modes, cfg["MODE_AC"], lambda v: disp("MODE_AC", v)),
            combo_row("On battery", "Used whenever you are unplugged", modes, cfg["MODE_BAT"], lambda v: disp("MODE_BAT", v))],
            desc="Quiet: least power and fan noise (CPU capped near 4 GHz, 60 Hz, no blur), the longest battery life. Balanced: everyday. "
                 "Performance: CPU and fans unrestricted, louder and hotter. Super+Alt+M cycles the mode for the power source you are on."),
        group("Low battery", [
            switch_row("Switch to Quiet automatically", "When the battery gets low, until you plug in", cfg["AUTOQUIET"] == "1", lambda on: setv("AUTOQUIET", "1" if on else "0")),
            spin_row("Switch at (percent)", "Quiet mode starts at or below this charge and ends once it is 5 points higher or you plug in", 5, 50, int(cfg["AUTOQUIET_PCT"]),
                     lambda v: (setv("AUTOQUIET_PCT", v), bg(str(SD / "power-watch.sh"), "autoquiet")))],
              desc="Your usual mode on battery stays as chosen above; this only overrides it while the battery is low."),
        group("Keeping the screen on", [
            switch_row("Keep screen awake", "No auto-lock or screen-off until you turn it off (the lid still sleeps)", (STATE / "caffeine").exists(),
                       lambda on: bg(str(SD / "caffeine.sh"), "on" if on else "off")),
            switch_row("Automatic caffeine", "Stay awake while a window is fullscreen or an app uses the microphone", cfg["AUTOCAFFEINE"] == "1", autocaf)]),
        group("Lock and screen off", [
            spin_row("Lock after, on AC (minutes)", "Screen locks after this many idle minutes.", 1, 120, int(cfg["LOCK_AC"]), lambda v: timers("LOCK_AC", v)),
            spin_row("Screen off after, on AC (minutes)", "The display powers off after this many idle minutes.", 1, 120, int(cfg["OFF_AC"]), lambda v: timers("OFF_AC", v)),
            spin_row("Lock after, on battery (minutes)", "Shorter on battery saves power and keeps it safe.", 1, 120, int(cfg["LOCK_BAT"]), lambda v: timers("LOCK_BAT", v)),
            spin_row("Screen off after, on battery (minutes)", None, 1, 120, int(cfg["OFF_BAT"]), lambda v: timers("OFF_BAT", v))])]
    return res + fan_group(cfg)

def page_input(cfg):
    def inp(k, v): setv(k, v); bg(str(SD / "input-apply.sh"))
    return [
        group("Touchpad", [
            switch_row("Tap to click", "Tap the touchpad instead of pressing it.", cfg["TP_TAP"] == "1", lambda on: inp("TP_TAP", "1" if on else "0")),
            switch_row("Natural scrolling", "Content follows your fingers, like a phone.", cfg["TP_NATURAL"] == "1", lambda on: inp("TP_NATURAL", "1" if on else "0")),
            switch_row("Ignore touchpad while typing", "Stops the cursor jumping when your palm brushes the pad.", cfg["TP_DWT"] == "1", lambda on: inp("TP_DWT", "1" if on else "0"))]),
        group("Pointer", [
            scale_row("Pointer speed", "Touchpad and mice. Right is faster. Applies to devices connected right now.", -100, 100, 5, float(cfg["PTR_SPEED"]) * 100, lambda v: f"{int(v)}",
                      lambda v: inp("PTR_SPEED", f"{v / 100:.2f}"))]),
        group("Keyboard", [
            spin_row("Repeat delay (ms)", "How long you hold a key before it starts repeating.", 150, 800, int(cfg["KEY_DELAY"]), lambda v: inp("KEY_DELAY", v), 10),
            spin_row("Repeat rate (per second)", "How fast it repeats once it starts.", 10, 100, int(cfg["KEY_RATE"]), lambda v: inp("KEY_RATE", v), 5)])]

def page_windows(cfg):
    i3 = (HOME / ".config/i3/config").read_text()
    ffm = re.search(r"^focus_follows_mouse\s+(yes|no)", i3, re.M); bw = re.search(r"^default_border pixel (\d+)", i3, re.M)
    kt = (HOME / ".config/kitty/kitty.conf").read_text() if (HOME / ".config/kitty/kitty.conf").exists() else ""
    op = re.search(r"^background_opacity\s+([0-9.]+)", kt, re.M)
    def kitty_opacity(v):
        f = HOME / ".config/kitty/kitty.conf"; t = f.read_text()
        t2 = re.sub(r"^background_opacity\s+[0-9.]+", f"background_opacity {v / 100:.2f}", t, flags=re.M)
        if t2 != t: f.write_text(t2)
        bg("pkill", "-USR1", "-x", "kitty")                    # kitty reloads its config
    lock = STATE / "autorotate.lock"
    return [
        group("Windows", [
            switch_row("Focus follows mouse", "The window under the pointer gets keyboard focus without clicking.", not ffm or ffm.group(1) == "yes",
                       lambda on: i3_edit(r"^focus_follows_mouse\s+(yes|no)", f"focus_follows_mouse {'yes' if on else 'no'}")),
            spin_row("Border thickness (px)", "The coloured outline that shows which window has focus. 0 hides it.", 0, 8, int(bw.group(1)) if bw else 2,
                     lambda v: i3_edit(r"^default_border pixel \d+", f"default_border pixel {v}"))]),
        group("Terminal", [
            scale_row("Opacity", "100 % is solid black; lower lets the blurred wallpaper through. Open terminals update at once.", 40, 100, 2,
                      float(op.group(1)) * 100 if op else 78, lambda v: f"{int(v)} %", kitty_opacity)]),
        group("Screen", [
            switch_row("Freeze rotation", "Stop the screen rotating with the accelerometer (for example while lying down).", lock.exists(),
                       lambda on: bg(str(SD / "autorotate.sh"), "lock") if on != lock.exists() else None),
            switch_row("Tablet mode", "On-screen keyboard that appears when you touch a text field. Always off after login.",
                       run("pgrep", "-x", "-u", str(os.getuid()), "onboard") != "", lambda on: bg(str(SD / "tablet.sh"), "on" if on else "off"))])]

def page_bar(cfg):
    pb = HOME / ".config/polybar/config.ini"; txt = pb.read_text() if pb.exists() else ""
    m = re.search(r"^modules-right\s*=\s*(.*)$", txt, re.M); cur = m.group(1).split() if m else []
    def bar_item(key, on):
        f = pb; t = f.read_text(); mm = re.search(r"^modules-right\s*=\s*(.*)$", t, re.M)
        have = set(mm.group(1).split()) if mm else set()
        (have.add if on else have.discard)(key)
        order = [k for k, _ in BAR_MODULES]
        new = " ".join([k for k in order if k in have] + [k for k in have if k not in order])
        f.write_text(re.sub(r"^modules-right\s*=.*$", f"modules-right = {new}", t, flags=re.M)); bg("polybar-msg", "cmd", "restart")
    def font(weight=None, size=None):
        t = pb.read_text(); mm = re.search(r"^font-1\s*=\s*(.*)$", t, re.M); curf = mm.group(1) if mm else "JetBrains Mono:weight=light:size=12;4"
        w = weight or (re.search(r"weight=(\w+)", curf).group(1) if re.search(r"weight=(\w+)", curf) else "light")
        z = size or (re.search(r"size=(\d+)", curf).group(1) if re.search(r"size=(\d+)", curf) else "12")
        line = f"font-1 = JetBrains Mono:weight={w}:size={z};4"
        t = re.sub(r"^font-1\s*=.*$", line, t, flags=re.M) if mm else t.replace("font-0 =", line + "\nfont-0 =", 1)
        pb.write_text(t); bg("polybar-msg", "cmd", "restart")
    def marker(v):
        t = pb.read_text()
        if v == "line":
            t = re.sub(r"^label-active-background\s*=.*$", "label-active-background =", t, flags=re.M)
            t = re.sub(r"^label-active-foreground\s*=.*$", "label-active-foreground = ${colors.mauve}", t, flags=re.M)
            t = re.sub(r"^line-size\s*=.*$", "line-size = 3pt", t, flags=re.M)
        else:
            t = re.sub(r"^label-active-background\s*=.*$", "label-active-background = ${colors.mauve}", t, flags=re.M)
            t = re.sub(r"^label-active-foreground\s*=.*$", "label-active-foreground = ${colors.crust}", t, flags=re.M)
            t = re.sub(r"^line-size\s*=.*$", "line-size = 2pt", t, flags=re.M)
        pb.write_text(t); bg("polybar-msg", "cmd", "restart")
    f1 = re.search(r"^font-1\s*=\s*(.*)$", txt, re.M)
    wt = (re.search(r"weight=(\w+)", f1.group(1)) or [None, "light"])[1] if f1 else "light"
    sz = (re.search(r"size=(\d+)", f1.group(1)) or [None, "12"])[1] if f1 else "12"
    mk = "box" if re.search(r"^label-active-background\s*=\s*\S", txt, re.M) else "line"
    return [
        group("Shown in the bar", [switch_row(label, None, key in cur, lambda on, k=key: bar_item(k, on)) for key, label in BAR_MODULES]),
        group("Workspaces", [
            switch_row("Show app icons next to the numbers", "Off by default: it makes each workspace's box wider",
                       cfg["WS_ICONS"] == "1", lambda on: (setv("WS_ICONS", "1" if on else "0"), bg("sh", "-c", 'kill -USR1 "$(cat "${XDG_RUNTIME_DIR:-/tmp}/display-agent.pid")"'))),
            combo_row("Active workspace marker", "A small filled box, or just a thin line under the number.", [("box", "Box"), ("line", "Line")], mk, marker),
            combo_row("Number weight", "How heavy the workspace numbers look.", [("light", "Light"), ("regular", "Regular"), ("medium", "Medium")], wt, lambda v: font(weight=v)),
            spin_row("Number size", "Points.", 8, 18, int(sz), lambda v: font(size=v))])]

def page_spotlight(cfg, win):
    return [
        group("Appearance", [
            scale_row("Transparency", "How much of the screen shows through Spotlight. Left is more see-through, 100 % is solid. Applies the next time you open it.", 35, 100, 1,
                      float(cfg["SPOT_OPACITY"]), lambda v: f"{int(v)} % opaque", lambda v: setv("SPOT_OPACITY", int(v)))]),
        group("Behaviour", [
            switch_row("Recents when opened", "Show your last four apps and files before you type anything.", cfg["SPOT_RECENTS"] == "1", lambda on: setv("SPOT_RECENTS", "1" if on else "0")),
            button_row("Deep search folders", "Where “search inside documents” looks (notes, PDFs and text files).", "Choose…", lambda: deep_roots_dialog(win))]),
        group("Clipboard history", [Adw.ActionRow(title="Everything you copy is kept", subtitle="Text and images, up to 3000 entries. Open it with Super+Shift+V, or type “c ” in Spotlight to search it.")]),
        group("Shortcuts inside Spotlight", [Adw.ActionRow(title="Preview a file", subtitle="Select a result and press Ctrl+Y (images, PDFs, text, folders). Esc goes back."),
                                              Adw.ActionRow(title="Browse every app", subtitle="Alt+A, or “Show all” in the recents view."),
                                              Adw.ActionRow(title="Timers and reminders", subtitle="timer 25m  ·  remind in 10m call back  ·  remind 15:30 stand up  ·  timers (list or cancel)")])]

def page_general(cfg, win, relook):
    def look(k, v): setv(k, v); relook(); bg(str(SD / "accent.sh"))
    cb = Gtk.ColorDialogButton(dialog=Gtk.ColorDialog()); cb.set_valign(Gtk.Align.CENTER)
    rgba = Gdk.RGBA(); rgba.parse(cfg["ACCENT_HEX"]); cb.set_rgba(rgba)
    def picked(btn, _p):
        c = btn.get_rgba(); hx = "#%02x%02x%02x" % (round(c.red * 255), round(c.green * 255), round(c.blue * 255))
        setv("ACCENT_HEX", hx); setv("ACCENT_MODE", "custom"); relook(); bg(str(SD / "accent.sh"))
    cb.connect("notify::rgba", picked)
    crow = Adw.ActionRow(title="Custom accent colour", subtitle="Choosing a colour here switches the accent to Custom"); crow.add_suffix(cb)
    return [
        group("Appearance", [
            combo_row("Theme", "Spotlight, Settings and timer alerts. “Follow the night schedule” is dark between the night-tint hours (Display page).",
                      [("light", "Light"), ("dark", "Dark"), ("schedule", "Follow the night schedule")], cfg["APPEARANCE"], lambda v: look("APPEARANCE", v)),
            combo_row("Accent colour", "Used for selections, switches and highlights, in the bar's active workspace and on the focused window's border",
                      [("amber", "Amber (default)"), ("wallpaper", "From the wallpaper"), ("custom", "Custom")], cfg["ACCENT_MODE"], lambda v: look("ACCENT_MODE", v)), crow]),
        group("Startup", [switch_row("Start with the microphone muted", "Every login begins muted; unmute when you need it.", cfg["MIC_MUTE_LOGIN"] == "1", lambda on: setv("MIC_MUTE_LOGIN", "1" if on else "0"))]),
        group("Your settings", [button_row("Export settings", "Saves your settings, Spotlight aliases and folder lists to a file you can keep", "Export…", lambda: do_export(win)),
                                button_row("Import settings", "Loads a file made by Export (for example on a fresh install)", "Import…", lambda: do_import(win))]),
        group("Timers and reminders", [switch_row("Play a sound when one rings", "Set them in Spotlight: timer 25m, remind in 10m call back, remind 15:30 stand up", cfg["ALARM_SOUND"] == "1", lambda on: setv("ALARM_SOUND", "1" if on else "0"))]),
        group("Screenshots", [switch_row("Keep a file of screenshots", "Besides the clipboard, save each screenshot in ~/Pictures. Off means clipboard only.", cfg["SHOT_SAVE"] == "1", lambda on: setv("SHOT_SAVE", "1" if on else "0"))])]

def bat_dir():
    root = Path(os.environ.get("ROG_PS", "/sys/class/power_supply"))
    return next(iter(sorted(root.glob("BAT*"))), None)

def bat_num(d, name):
    try: return float((d / name).read_text().strip())
    except Exception: return None

def bat_text(d, name):
    try: return (d / name).read_text().strip()
    except Exception: return ""

def bat_facts():
    """(title, value, subtitle) rows describing the battery right now."""
    d = bat_dir()
    if d is None: return [("Battery", "not found", "")]
    cap = bat_num(d, "capacity"); st = bat_text(d, "status"); full = bat_num(d, "energy_full"); des = bat_num(d, "energy_full_design")
    now = bat_num(d, "energy_now"); pw = bat_num(d, "power_now"); v = bat_num(d, "voltage_now"); cyc = bat_num(d, "cycle_count")
    rows = [("Charge", f"{cap:.0f} %  ·  {st}" if cap is not None else "?", "")]
    if full and des: rows.append(("Battery health", f"{full / des * 100:.0f} %", f"Holds {full / 1e6:.1f} Wh today, {des / 1e6:.1f} Wh when new"))
    rows.append(("Charge cycles", f"{cyc:.0f}" if cyc else "not reported", "This battery does not report a cycle count" if not cyc else ""))
    if pw and pw > 0:
        rows.append(("Power draw", f"{pw / 1e6:.1f} W", "Right now, whole machine" if st == "Discharging" else "Going into the battery"))
        if st == "Discharging" and now: hrs = now / pw; rows.append(("Time left", f"{int(hrs)} h {int((hrs % 1) * 60):02d} min", "At the current draw"))
        elif st == "Charging" and full and now: hrs = (full - now) / pw; rows.append(("Time to full", f"{int(hrs)} h {int((hrs % 1) * 60):02d} min", "At the current charging power"))
    else:
        rows.append(("Power draw", "—", "Plugged in and full" if st in ("Full", "Not charging") else ""))
    if v: rows.append(("Voltage", f"{v / 1e6:.2f} V", ""))
    rows.append(("Battery", f"{bat_text(d, 'model_name')}  ·  {bat_text(d, 'technology')}", ""))
    return rows

def page_battery(cfg, win):
    g = Adw.PreferencesGroup(title="Battery status", description="Updates every few seconds while this page is open.")
    rows = []
    def build():
        for r in rows: g.remove(r)
        rows.clear()
        for title, value, sub in bat_facts():
            r = Adw.ActionRow(title=title, subtitle=sub); lab = Gtk.Label(label=value); lab.add_css_class("dim-label"); lab.set_valign(Gtk.Align.CENTER)
            r.add_suffix(lab); g.add(r); rows.append(r)
        return win.get_visible() if win else True
    build()
    GLib.timeout_add_seconds(3, lambda: build() and True)
    tips = Adw.PreferencesGroup(title="Notes")
    tips.add(Adw.ActionRow(title="Reading these numbers", subtitle="A new battery reports 100 % health; around 80 % it holds noticeably less charge than when new. "
                                                                  "Quiet mode (Power & Performance) gives the longest runtime."))
    return [g, tips]

# ---------------------------------------------------------------- Sound: output/input devices, volumes, per-app volume
def pj(*args):
    try: return json.loads(subprocess.run(["pactl", "-f", "json", *args], capture_output=True, text=True, timeout=5).stdout or "[]")
    except Exception: return []

def vol_pct(d):
    try: return int(round(float(next(iter(d["volume"].values()))["value_percent"].strip("%"))))
    except Exception: return 100

def page_sound(cfg, win):
    sinks = pj("list", "sinks"); srcs = [x for x in pj("list", "sources") if not x["name"].endswith(".monitor")]
    dsink = run("pactl", "get-default-sink"); dsrc = run("pactl", "get-default-source")
    cur_s = next((x for x in sinks if x["name"] == dsink), sinks[0] if sinks else None)
    cur_i = next((x for x in srcs if x["name"] == dsrc), srcs[0] if srcs else None)
    groups = []
    rows = []
    if sinks:
        rows.append(combo_row("Device", None, [(x["name"], x["description"]) for x in sinks], cur_s["name"], lambda v: bg("pactl", "set-default-sink", v)))
        rows.append(scale_row("Volume", None, 0, 150, 1, vol_pct(cur_s), lambda v: f"{int(v)} %", lambda v: bg("pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{int(v)}%")))
        rows.append(switch_row("Muted", None, bool(cur_s.get("mute")), lambda on: bg("pactl", "set-sink-mute", "@DEFAULT_SINK@", "1" if on else "0")))
    groups.append(group("Output", rows or [Adw.ActionRow(title="No output device found")]))
    rows = []
    if srcs:
        rows.append(combo_row("Device", None, [(x["name"], x["description"]) for x in srcs], cur_i["name"], lambda v: bg("pactl", "set-default-source", v)))
        rows.append(scale_row("Volume", None, 0, 150, 1, vol_pct(cur_i), lambda v: f"{int(v)} %", lambda v: bg("pactl", "set-source-volume", "@DEFAULT_SOURCE@", f"{int(v)}%")))
        rows.append(switch_row("Muted", "The bar's mic indicator shows this", bool(cur_i.get("mute")), lambda on: bg("pactl", "set-source-mute", "@DEFAULT_SOURCE@", "1" if on else "0")))
    groups.append(group("Input", rows or [Adw.ActionRow(title="No microphone found")]))
    apps = Adw.PreferencesGroup(title="Volume per app", description="Apps that are playing sound right now.")
    state = {"rows": [], "key": None}
    def rebuild():
        inputs = pj("list", "sink-inputs"); key = tuple((x["index"], vol_pct(x)) for x in inputs)
        if key == state["key"]: return win.get_visible() if win else True
        state["key"] = key
        for r in state["rows"]: apps.remove(r)
        state["rows"] = []
        if not inputs:
            r = Adw.ActionRow(title="Nothing is playing"); apps.add(r); state["rows"].append(r)
        for x in inputs:
            p = x.get("properties", {}); name = p.get("application.name") or p.get("media.name") or "Sound"
            r = scale_row(name, p.get("media.name") if p.get("media.name") != name else None, 0, 150, 1, vol_pct(x), lambda v: f"{int(v)} %",
                          lambda v, i=x["index"]: bg("pactl", "set-sink-input-volume", str(i), f"{int(v)}%"))
            apps.add(r); state["rows"].append(r)
        return win.get_visible() if win else True
    rebuild(); GLib.timeout_add_seconds(4, lambda: rebuild() and True)
    groups.append(apps)
    return groups

# ---------------------------------------------------------------- Startup apps (XDG autostart; i3's own `exec` lines are not touched)
SYS_AUTOSTART = Path("/etc/xdg/autostart"); USER_AUTOSTART = HOME / ".config/autostart"

def desktop_field(text, key):
    m = re.search(rf"^{key}=(.*)$", text, re.M); return m.group(1).strip() if m else ""

def startup_entries():
    names = {}
    for d in (SYS_AUTOSTART, USER_AUTOSTART):
        if d.is_dir():
            for f in d.glob("*.desktop"): names[f.name] = None
    out = []
    for n in sorted(names):
        user = USER_AUTOSTART / n; sysf = SYS_AUTOSTART / n
        txt = (user if user.exists() else sysf).read_text(errors="replace")
        base = (sysf if sysf.exists() else user).read_text(errors="replace")
        title = desktop_field(base, "Name") or desktop_field(txt, "Name") or n
        if title.endswith("(hidden by rog-tune)"): title = title.replace(" (hidden by rog-tune)", "")
        hidden = desktop_field(txt, "Hidden").lower() == "true" or desktop_field(txt, "NoDisplay").lower() == "true" and False
        if desktop_field(txt, "OnlyShowIn") and "i3" not in desktop_field(txt, "OnlyShowIn"): pass
        out.append((n, title, desktop_field(base, "Comment") or desktop_field(base, "Exec"), not hidden))
    return out

def set_startup(name, on):
    user = USER_AUTOSTART / name; sysf = SYS_AUTOSTART / name
    USER_AUTOSTART.mkdir(parents=True, exist_ok=True)
    if on:
        if user.exists():
            t = user.read_text()
            if sysf.exists() and re.search(r"^Hidden=true", t, re.M) and len(t.strip().splitlines()) <= 6: user.unlink()      # our stub: just remove it
            else: user.write_text(re.sub(r"^Hidden=true", "Hidden=false", t, flags=re.M))
    else:
        if user.exists():
            t = user.read_text()
            user.write_text(re.sub(r"^Hidden=\w+", "Hidden=true", t, flags=re.M) if re.search(r"^Hidden=", t, re.M) else t.rstrip("\n") + "\nHidden=true\n")
        else:
            user.write_text(f"# rog-settings: switched off from Settings\n[Desktop Entry]\nType=Application\nName={name}\nHidden=true\n")

def page_startup(cfg, win):
    rows = [switch_row(title, sub[:90], on, lambda on_, n=n: set_startup(n, on_)) for n, title, sub, on in startup_entries()]
    return [group("Programs that start when you log in", rows or [Adw.ActionRow(title="No startup entries")],
                  desc="Changes apply at your next login. Programs started from the i3 config itself (the bar, the compositor, the agents) are not listed here.")]

# ---------------------------------------------------------------- Wallpaper
def page_wallpaper(cfg, win):
    def every(v):
        setv("WALL_EVERY", v); bg(str(SD / "wallpaper-timer.sh"))
    return [
        group("Day and night", [
            spin_row("Day wallpapers start at (hour)", "Wallpapers from the day folder are used from this hour…", 0, 23, int(cfg["WALL_DAY_START"]), lambda v: setv("WALL_DAY_START", v)),
            spin_row("Night wallpapers start at (hour)", "…until this hour, then the night folder", 0, 23, int(cfg["WALL_NIGHT_START"]), lambda v: setv("WALL_NIGHT_START", v))],
              desc="Your wallpapers live in ~/Pictures/wallpapers/day and /night."),
        group("Changing", [
            spin_row("Change automatically every (minutes)", "0 means only when you press Super+Y", 0, 1440, int(cfg["WALL_EVERY"]), every, 5),
            button_row("Change it now", "Same as Super+Y", "Next wallpaper", lambda: bg(str(HOME / ".config/wallpaper-config/wallpaper-cycle.sh")))])]

# ---------------------------------------------------------------- Fans (asusctl)
FAN_CURVES = {
    "quiet": {"cpu": "45c:0%,55c:0%,60c:12%,65c:25%,70c:40%,75c:55%,80c:75%,90c:100%", "gpu": "50c:0%,60c:0%,65c:15%,70c:30%,75c:45%,80c:65%,85c:80%,90c:100%"},
    "cool": {"cpu": "40c:10%,50c:20%,55c:35%,60c:50%,65c:62%,70c:75%,80c:90%,90c:100%", "gpu": "40c:10%,50c:20%,55c:35%,60c:50%,65c:62%,70c:75%,80c:90%,90c:100%"}}

def apply_fans(kind):
    for prof in ("Quiet", "Balanced", "Performance"):
        if kind == "default":
            subprocess.run(["asusctl", "fan-curve", "--mod-profile", prof, "--enable-fan-curves", "false"], capture_output=True, timeout=10); continue
        for fan in ("cpu", "gpu"):
            subprocess.run(["asusctl", "fan-curve", "--mod-profile", prof, "--fan", fan, "--data", FAN_CURVES[kind][fan]], capture_output=True, timeout=10)
        subprocess.run(["asusctl", "fan-curve", "--mod-profile", prof, "--enable-fan-curves", "true"], capture_output=True, timeout=10)

def fan_group(cfg):
    if not any(Path(p, "asusctl").exists() for p in os.environ.get("PATH", "").split(":")): return []
    en = run("asusctl", "fan-curve", "--get-enabled")
    cur = cfg["FAN_CURVE"] if "enabled: true" in en else "default"
    return [group("Fans", [combo_row("Fan curve", "How early the fans spin up as the machine warms", [("default", "Firmware default"), ("quiet", "Quieter (later, gentler)"), ("cool", "Cooler (earlier)")], cur,
                                     lambda v: (setv("FAN_CURVE", v), threading.Thread(target=apply_fans, args=(v,), daemon=True).start()))],
                   desc="Every curve still reaches full speed by 90 °C, and the CPU throttles itself long before it can be hurt. “Firmware default” hands control back to the machine.")]

# ---------------------------------------------------------------- System
def page_system(cfg, win):
    def sh1(*a): return run(*a) or "?"
    rows = []
    du = shutil.disk_usage("/"); dh = shutil.disk_usage(str(HOME))
    rows.append(("System disk", f"{du.free / 1e9:.0f} GB free of {du.total / 1e9:.0f} GB"))
    rows.append(("Home disk", f"{dh.free / 1e9:.0f} GB free of {dh.total / 1e9:.0f} GB"))
    try:
        mem = dict(l.split(":") for l in Path("/proc/meminfo").read_text().splitlines()); tot = int(mem["MemTotal"].split()[0]); av = int(mem["MemAvailable"].split()[0])
        rows.append(("Memory", f"{(tot - av) / 1e6:.1f} GB used of {tot / 1e6:.1f} GB"))
    except Exception: pass
    up = float(Path("/proc/uptime").read_text().split()[0]); rows.append(("Up for", f"{int(up // 3600)} h {int(up % 3600 // 60)} min"))
    rows.append(("Kernel", sh1("uname", "-r")))
    g1 = group("This machine", [(lambda t, v: (lambda r: (r.add_suffix(Gtk.Label(label=v, css_classes=["dim-label"])), r)[1])(Adw.ActionRow(title=t)))(t, v) for t, v in rows])
    health = Path("/var/lib/rog/health.txt")
    if health.exists():
        txt = health.read_text(errors="replace").strip(); when = time.strftime("%d %b %Y, %H:%M", time.localtime(health.stat().st_mtime))
        hr = [Adw.ActionRow(title=l.split(":", 1)[0].strip(), subtitle=l.split(":", 1)[1].strip()) if ":" in l else Adw.ActionRow(title=l.strip()) for l in txt.splitlines() if l.strip()][:14]
        g2 = group("SSD health", hr, desc=f"Checked {when} (weekly).")
    else:
        g2 = group("SSD health", [Adw.ActionRow(title="Not set up yet", subtitle="Install smartmontools, then:  sudo ~/rog-tune/rog-tune.sh --apply health")])
    return [g1, g2]

# ---------------------------------------------------------------- export / import of my settings
EXPORT_FILES = [".config/rog/settings.env", ".config/spotlight/aliases", ".config/spotlight/roots", ".config/spotlight/sync.list"]

def do_export(win):
    fd = Gtk.FileDialog(title="Export settings"); fd.set_initial_name(time.strftime("rog-settings-%Y%m%d.tar.gz"))
    def done(d, res):
        try: f = d.save_finish(res)
        except GLib.Error: return
        with tarfile.open(f.get_path(), "w:gz") as t:
            for rel in EXPORT_FILES:
                p = HOME / rel
                if p.exists(): t.add(str(p), arcname=rel)
    fd.save(win, None, done)

def do_import(win):
    fd = Gtk.FileDialog(title="Import settings")
    def done(d, res):
        try: f = d.open_finish(res)
        except GLib.Error: return
        with tarfile.open(f.get_path()) as t:
            for m in t.getmembers():
                if m.name in EXPORT_FILES and m.isfile():
                    dest = HOME / m.name; dest.parent.mkdir(parents=True, exist_ok=True); dest.write_bytes(t.extractfile(m).read())
        for c in (["power-watch.sh", "display"], ["nightlight.sh", "reapply"], ["input-apply.sh"]): bg(str(SD / c[0]), *c[1:])
    fd.open(win, None, done)

def page_backup(cfg, win):
    return [
        group("Back up to hp-server", [
            button_row("Choose folders and back up", "Manual only. Copies the folders you pick to the external drive on hp-server (~/Media/rog-backup). Only new and changed files are sent.",
                       "Choose and back up…", lambda: backup_flow(win), suggested=True),
            switch_row("Mirror deletions", "Also remove files from the backup that you deleted here, so it keeps only the current versions. Off: deleted files stay in the backup.",
                       cfg["BACKUP_MIRROR"] == "1", lambda on: setv("BACKUP_MIRROR", "1" if on else "0"))])]

# ---------------------------------------------------------------- window
FONT_CSS = "window.rogwin { font-size: 118%; } window.rogwin .title-4 { font-size: 120%; }"
def effective_dark(cfg):
    mode = cfg.get("APPEARANCE", "light")
    if mode == "dark": return True
    if mode != "schedule": return False
    try: a = int(cfg["NIGHT_START"]); b = int(cfg["NIGHT_END"])
    except Exception: a, b = 19, 7
    h = time.localtime().tm_hour
    return (h >= a or h < b) if a > b else (a <= h < b)

def effective_accent(cfg):
    m = cfg.get("ACCENT_MODE", "amber")
    try:
        if m == "custom" and re.match(r"^#[0-9a-fA-F]{6}$", cfg.get("ACCENT_HEX", "")): return cfg["ACCENT_HEX"]
        if m == "wallpaper":
            v = (HOME / ".cache/accent-wallpaper").read_text().strip()
            if re.match(r"^#[0-9a-fA-F]{6}$", v): return v
    except Exception: pass
    return "#c47f1c"

def accent_css(cfg):
    h = effective_accent(cfg); r, g, b = (int(h[i:i + 2], 16) for i in (1, 3, 5))
    lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255
    dark = effective_dark(cfg)
    text = "#%02x%02x%02x" % tuple(min(255, int(x * 1.2 + 25)) if dark else int(x * 0.85) for x in (r, g, b))
    return f"@define-color accent_bg_color {h}; @define-color accent_color {text}; @define-color accent_fg_color {'#1d150b' if lum > 0.62 else '#ffffff'};"

class SettingsWindow(Adw.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title="Settings", default_width=1280, default_height=800)
        self.add_css_class("rogwin")
        cfg = load(); self.accent = Gtk.CssProvider()
        Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), self.accent, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        fp = Gtk.CssProvider(); fp.load_from_string(FONT_CSS); Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), fp, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        self.apply_look(cfg)
        pages = [("Display", "video-display-symbolic", page_display(cfg)),
                 ("Power & Performance", "power-profile-balanced-symbolic", page_power(cfg)),
                 ("Battery", "battery-symbolic", page_battery(cfg, self)),
                 ("Keyboard & Mouse", "input-keyboard-symbolic", page_input(cfg)),
                 ("Windows & Terminal", "window-new-symbolic", page_windows(cfg)),
                 ("Sound", "audio-volume-high-symbolic", page_sound(cfg, self)),
                 ("Wallpaper", "preferences-desktop-wallpaper-symbolic", page_wallpaper(cfg, self)),
                 ("Top Bar", "view-list-symbolic", page_bar(cfg)),
                 ("Startup Apps", "system-run-symbolic", page_startup(cfg, self)),
                 ("Spotlight", "system-search-symbolic", page_spotlight(cfg, self)),
                 ("General", "preferences-system-symbolic", page_general(cfg, self, lambda: self.apply_look(load()))),
                 ("System", "computer-symbolic", page_system(cfg, self)),
                 ("Backup", "drive-harddisk-symbolic", page_backup(cfg, self))]
        self.stack = Gtk.Stack(); self.stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE)
        side = Gtk.ListBox(); side.add_css_class("navigation-sidebar"); side.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.reg = []; self.side_rows = {}
        def walk(w):
            c = w.get_first_child()
            while c: yield c; yield from walk(c); c = c.get_next_sibling()
        for name, icon, groups in pages:
            sc = Gtk.ScrolledWindow(); sc.set_hexpand(True); sc.set_vexpand(True)
            clamp = Adw.Clamp(maximum_size=1400, tightening_threshold=1100, margin_top=28, margin_bottom=48, margin_start=40, margin_end=40)   # wide pages for a full-screen window
            body = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=32)
            for g in groups: body.append(g)
            clamp.set_child(body); sc.set_child(clamp); self.stack.add_named(sc, name)
            for w in walk(body):
                if isinstance(w, Adw.PreferencesGroup):
                    if w.get_title(): self.reg.append((name, w, w.get_title(), w.get_description() or ""))
                if isinstance(w, Adw.PreferencesRow):
                    sub = w.get_subtitle() if hasattr(w, "get_subtitle") else ""
                    if w.get_title(): self.reg.append((name, w, w.get_title(), sub or ""))
            box = Gtk.Box(spacing=12); box.set_margin_top(10); box.set_margin_bottom(10); box.set_margin_start(6)
            box.append(Gtk.Image.new_from_icon_name(icon)); lab = Gtk.Label(label=name, xalign=0); box.append(lab)
            row = Gtk.ListBoxRow(); row.set_child(box); row.page_name = name; side.append(row); self.side_rows[name] = row
        self.wtitle = Adw.WindowTitle(title="Display", subtitle="")
        side.connect("row-selected", lambda lb, r: self.show_page(r.page_name) if r else None)
        split = Adw.NavigationSplitView(); split.set_min_sidebar_width(300); split.set_max_sidebar_width(360)
        sb = Adw.ToolbarView(); hb = Adw.HeaderBar(); hb.set_title_widget(Adw.WindowTitle(title="Settings", subtitle="")); sb.add_top_bar(hb)
        self.search = Gtk.SearchEntry(placeholder_text="Search settings"); self.search.set_margin_start(10); self.search.set_margin_end(10); self.search.set_margin_bottom(6)
        sb.add_top_bar(self.search)
        self.results = Gtk.ListBox(); self.results.add_css_class("boxed-list"); self.results.set_selection_mode(Gtk.SelectionMode.NONE)
        rsc = Gtk.ScrolledWindow(); rcl = Adw.Clamp(maximum_size=1400, tightening_threshold=1100, margin_top=28, margin_bottom=48, margin_start=40, margin_end=40)
        rcl.set_child(self.results); rsc.set_child(rcl); self.stack.add_named(rsc, "__search__")
        self.search.connect("search-changed", self.on_search)
        sb.set_content(side); split.set_sidebar(Adw.NavigationPage.new(sb, "Settings"))
        self.side = side
        cb = Adw.ToolbarView(); ch = Adw.HeaderBar(); ch.set_title_widget(self.wtitle); cb.add_top_bar(ch); cb.set_content(self.stack)
        split.set_content(Adw.NavigationPage.new(cb, "Display"))
        self.set_content(split)
        side.select_row(side.get_row_at_index(int(os.environ.get("ROG_SETTINGS_PAGE", "0")) % len(pages)))
        def keys(c, kv, kc, st):
            if kv == Gdk.KEY_Escape:
                if self.search.get_text(): self.search.set_text(""); return True
                self.close(); return True
            if kv == Gdk.KEY_f and st & Gdk.ModifierType.CONTROL_MASK: self.search.grab_focus(); return True
            return False
        k = Gtk.EventControllerKey(); k.connect("key-pressed", keys); self.add_controller(k)

    def on_search(self, entry):
        text = entry.get_text().strip().lower()
        if not text:
            r = self.side.get_selected_row()
            if r: self.show_page(r.page_name)
            return
        child = self.results.get_first_child()
        while child: nxt = child.get_next_sibling(); self.results.remove(child); child = nxt
        hits = [(p, w, t, sub) for p, w, t, sub in self.reg if text in f"{t} {sub} {p}".lower()][:40]
        for p, w, t, sub in hits:
            r = Adw.ActionRow(title=t, subtitle=f"{p}" + (f"  ·  {sub}" if sub else "")); r.set_activatable(True)
            r.connect("activated", lambda _r, p=p, w=w: self.jump(p, w)); self.results.append(r)
        if not hits: self.results.append(Adw.ActionRow(title="No settings match", subtitle="Try another word"))
        self.stack.set_visible_child_name("__search__"); self.wtitle.set_title("Search")

    def jump(self, page, row):
        self.search.set_text(""); self.side.select_row(self.side_rows[page]); GLib.idle_add(lambda: (row.grab_focus(), False)[1])

    def show_page(self, name):
        self.stack.set_visible_child_name(name); self.wtitle.set_title(name)

    def apply_look(self, cfg):
        Adw.StyleManager.get_default().set_color_scheme(Adw.ColorScheme.FORCE_DARK if effective_dark(cfg) else Adw.ColorScheme.FORCE_LIGHT)
        self.accent.load_from_string(accent_css(cfg))

class App(Adw.Application):
    def __init__(self, backup_only=False):
        super().__init__(application_id="rog.Settings"); self.backup_only = backup_only
    def do_activate(self):
        if self.backup_only:
            Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), self._accent(), Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
            Adw.StyleManager.get_default().set_color_scheme(Adw.ColorScheme.FORCE_DARK if effective_dark(load()) else Adw.ColorScheme.FORCE_LIGHT)
            self.hold(); backup_flow(None, on_done=self.quit)
        else:
            SettingsWindow(self).present()
    def _accent(self):
        p = Gtk.CssProvider(); p.load_from_string(accent_css(load())); return p

def main():
    GLib.set_prgname("RogSettings"); GLib.set_application_name("RogSettings")
    Adw.init()
    sys.exit(App(backup_only="--backup" in sys.argv).run([sys.argv[0]]))

if __name__ == "__main__":
    main()
