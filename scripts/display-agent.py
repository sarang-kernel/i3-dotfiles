#!/usr/bin/env python3
# rog-tune: the display agent. One small process, no polling while it has nothing to do:
#   adaptive refresh  after N seconds without input the panel drops to the idle rate; the first key or touch brings the full rate back
#   cinema mode       a fullscreen video player (mpv, vlc, ...) switches the panel to a rate that divides the film's frame rate evenly
# The actual rate is chosen by `power-watch.sh refresh` (so Quiet mode, power source and these two always agree); this process only
# sets/clears two flag files and asks for a refresh.
import ctypes, json, math, os, select, signal, socket, subprocess, sys, threading, time
from pathlib import Path

HOME = Path.home()
RT = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp"))
ENV = HOME / ".config/rog/settings.env"
PW = HOME / ".config/scripts/power-watch.sh"
LOW, CIN, PAUSE, PIDF = RT / "adaptive.low", RT / "cinema.on", RT / "display-agent.pause", RT / "display-agent.pid"
CINHZ = RT / "cinema.hz"            # set when mpv reports the video's exact frame rate (read by power-watch.sh)
MPV_SOCK = HOME / ".cache/mpv-ipc"
PLAYERS = {"mpv", "vlc", "celluloid", "io.github.celluloid_player.celluloid", "smplayer", "totem", "kodi", "haruna", "mplayer",
           "parole", "jellyfinmediaplayer", "jellyfin media player", "dragon", "mpc-qt", "stremio"}

def cfg(key, default):
    try:
        for l in ENV.read_text().splitlines():
            if l.startswith(key + "="): return l.split("=", 1)[1].strip().strip('"')
    except Exception: pass
    return os.environ.get(key, default)

# ---- seconds since the last key/touch, from the X screensaver extension (no fork, no polling of other processes)
class Idle:
    def __init__(self):
        self.xcb = ctypes.CDLL("libxcb.so.1"); self.ss = ctypes.CDLL("libxcb-screensaver.so.0")
        self.xcb.xcb_connect.restype = ctypes.c_void_p; self.xcb.xcb_connect.argtypes = [ctypes.c_char_p, ctypes.c_void_p]
        self.conn = self.xcb.xcb_connect(None, None)
        self.xcb.xcb_get_setup.restype = ctypes.c_void_p; self.xcb.xcb_get_setup.argtypes = [ctypes.c_void_p]
        class Iter(ctypes.Structure): _fields_ = [("data", ctypes.POINTER(ctypes.c_uint32)), ("rem", ctypes.c_int), ("index", ctypes.c_int)]
        self.xcb.xcb_setup_roots_iterator.restype = Iter; self.xcb.xcb_setup_roots_iterator.argtypes = [ctypes.c_void_p]
        self.root = self.xcb.xcb_setup_roots_iterator(self.xcb.xcb_get_setup(self.conn)).data[0]    # first field of xcb_screen_t = root window
        self.ss.xcb_screensaver_query_info.restype = ctypes.c_uint; self.ss.xcb_screensaver_query_info.argtypes = [ctypes.c_void_p, ctypes.c_uint32]
        self.ss.xcb_screensaver_query_info_reply.restype = ctypes.c_void_p
        self.ss.xcb_screensaver_query_info_reply.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_void_p]
        self.libc = ctypes.CDLL("libc.so.6"); self.libc.free.argtypes = [ctypes.c_void_p]

    def ms(self):
        cookie = self.ss.xcb_screensaver_query_info(self.conn, self.root)
        rep = self.ss.xcb_screensaver_query_info_reply(self.conn, cookie, None)
        if not rep: return 0
        v = ctypes.c_uint32.from_address(rep + 16).value                 # ms_since_user_input
        self.libc.free(rep); return v

def sh(*cmd, t=3):
    try: return subprocess.run(list(cmd), capture_output=True, text=True, timeout=t).stdout
    except Exception: return ""

def refresh(): subprocess.run([str(PW), "refresh"], capture_output=True, timeout=20)

def busy_reasons():
    """Things that mean 'do not drop the refresh rate now': locked, screen off, caffeine (fullscreen/call), audio playing."""
    if sh("pgrep", "-x", "i3lock").strip(): return "locked"
    if "Monitor is Off" in sh("xset", "q"): return "screen off"
    if (RT / "autocaffeine.on").exists() or (Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "caffeine").exists(): return "caffeine"
    if sh("pactl", "list", "short", "sink-inputs").strip(): return "audio"
    return ""

def cinema_wanted():
    try: tree = json.loads(sh("i3-msg", "-t", "get_tree", t=4)); wss = json.loads(sh("i3-msg", "-t", "get_workspaces", t=4))
    except Exception: return False
    cur = next((w["name"] for w in wss if w.get("focused")), None)
    def walk(n, ws=None):
        if n.get("type") == "workspace": ws = n.get("name")
        if n.get("window") and n.get("fullscreen_mode") == 1 and ws == cur:
            cls = ((n.get("window_properties") or {}).get("class") or "").lower()
            if cls in PLAYERS: return True
        return any(walk(c, ws) for c in n.get("nodes", []) + n.get("floating_nodes", []))
    return walk(tree)

def mpv_fps():
    """Ask mpv (through its control socket) for the playing video's frame rate; None if it is not available."""
    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM); s.settimeout(1.0); s.connect(str(MPV_SOCK))
        s.sendall(b'{"command":["get_property","container-fps"]}\n'); buf = b""
        while b"\n" not in buf: buf += s.recv(4096)
        s.close()
        for line in buf.splitlines():
            d = json.loads(line)
            if d.get("error") == "success" and d.get("data"): return float(d["data"])
    except Exception: pass
    return None

def film_rate(fps):
    """The lowest rate (at least 58 Hz, at most 165) that shows every frame for the same number of refreshes: fps * 1, 2, 3 ..."""
    m = max(1, math.ceil(58.0 / fps - 1e-9)); r = fps * m
    while r > 165 and m > 1: m -= 1; r = fps * m
    return round(r, 3)

def match_fps_later():
    """Cinema mode with mpv: the file may take a moment to load, so retry a few times, then set the exact rate."""
    for _ in range(10):
        time.sleep(0.6)
        if not CIN.exists(): return
        fps = mpv_fps()
        if fps:
            CINHZ.write_text(str(film_rate(fps))); refresh(); return

WS_GLYPH = {"kitty": "\uf120", "firefox": "\uf269", "zen": "\uf269", "zen-alpha": "\uf269", "google-chrome": "\uf268", "chromium": "\uf268", "qutebrowser": "\uf0ac",
            "code": "\uf121", "thunar": "\uf07b", "mpv": "\uf04b", "vlc": "\uf04b", "obsidian": "\uf249", "ferdium": "\uf086", "discord": "\uf392",
            "signal": "\uf086", "libreoffice": "\uf15c", "zotero": "\uf02d", "evince": "\uf1c1", "zathura": "\uf1c1", "okular": "\uf1c1", "anki": "\uf24d"}

def sync_icons():
    """Workspace names like '2 \uf120 \uf269' (icons of what is on them) when WS_ICONS=1, plain numbers when 0. Safe: i3 binds use `workspace number N`."""
    on = cfg("WS_ICONS", "0") == "1"
    try:
        tree = json.loads(sh("i3-msg", "-t", "get_tree", t=4)); wss = json.loads(sh("i3-msg", "-t", "get_workspaces", t=4))
    except Exception: return
    icons = {}
    def walk(n, ws=None):
        if n.get("type") == "workspace": ws = n.get("name")
        if n.get("window") and ws and not ws.startswith("__"):
            cls = ((n.get("window_properties") or {}).get("class") or "").lower()
            g = WS_GLYPH.get(cls) or WS_GLYPH.get(cls.split(".")[-1]) or "\uf2d0"
            if g not in icons.setdefault(ws, []): icons[ws].append(g)
        for c in n.get("nodes", []) + n.get("floating_nodes", []): walk(c, ws)
    walk(tree)
    for w in wss:
        name = w["name"]; num = str(w.get("num", ""))
        if not num.isdigit() or num == "-1": continue
        want = (num + " " + " ".join(icons.get(name, [])[:3])).strip() if on else num
        if want != name:
            sh("i3-msg", f'rename workspace "{name}" to "{want}"')

def single_instance():
    try:
        old = int(PIDF.read_text())
        if old != os.getpid() and b"display-agent" in Path(f"/proc/{old}/cmdline").read_bytes():
            os.kill(old, signal.SIGTERM); time.sleep(0.4)
    except Exception: pass
    PIDF.write_text(str(os.getpid()))

def cam_watch():
    """Camera in use: inotify on the webcam's device node (no polling); the flag file + a bar ping when it changes."""
    import threading
    try:
        libc = ctypes.CDLL("libc.so.6", use_errno=True)
        devs = []
        for p in sorted(Path("/sys/class/video4linux").glob("video*")):
            try:
                if (p / "index").read_text().strip() == "0": devs.append("/dev/" + p.name)
            except Exception: pass
        if not devs: return
        fd = libc.inotify_init1(0)
        for d in devs: libc.inotify_add_watch(fd, d.encode(), 0x20 | 0x8 | 0x10)      # IN_OPEN | IN_CLOSE_WRITE | IN_CLOSE_NOWRITE
        flag = RT / "camera.on"; state = None
        while True:
            now = subprocess.run(["fuser", "-s", *devs], capture_output=True).returncode == 0
            if now != state:
                state = now
                (flag.touch() if now else flag.unlink(missing_ok=True))
                subprocess.run(["polybar-msg", "action", "#camera.hook.0"], capture_output=True)
            os.read(fd, 4096); time.sleep(0.25)                                       # blocks until the camera is opened or closed
    except Exception:
        return

def main():
    import threading
    threading.Thread(target=cam_watch, daemon=True).start()
    single_instance()
    idle = Idle()
    def bye(*a):
        for f in (LOW, CIN, CINHZ, RT / "camera.on"): f.unlink(missing_ok=True)
        try: refresh()
        except Exception: pass
        PIDF.unlink(missing_ok=True)
        subprocess.run(["pkill", "-P", str(os.getpid())], capture_output=True)       # the i3 subscription and any xinput wait
        os._exit(0)                                     # leave for certain, whatever the main loop was blocked on
    signal.signal(signal.SIGTERM, bye); signal.signal(signal.SIGINT, bye)
    signal.signal(signal.SIGUSR1, lambda *a: sync_icons())
    if cfg("WS_ICONS", "0") == "1": sync_icons()
    i3 = subprocess.Popen(["i3-msg", "-t", "subscribe", "-m", '["window","workspace"]'], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, bufsize=1)
    xin = None
    while True:
        thr = max(5, int(cfg("ADAPTIVE_IDLE_S", "60")))
        enabled = cfg("ADAPTIVE", "1") == "1" and not PAUSE.exists()
        # ---- waiting for input while the rate is low: block on the first input event (no polling at all)
        if LOW.exists():
            if xin is None: xin = subprocess.Popen(["xinput", "test-xi2", "--root"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, bufsize=1)
            r, _, _ = select.select([xin.stdout, i3.stdout], [], [], None)
            if xin.stdout in r:
                xin.stdout.readline(); xin.kill(); xin.wait(); xin = None
                LOW.unlink(missing_ok=True); refresh(); continue
        else:
            if xin is not None: xin.kill(); xin.wait(); xin = None
            ms = idle.ms(); idle_s = ms / 1000.0
            if enabled and not CIN.exists() and idle_s >= thr:
                if not busy_reasons():
                    base = sh(str(PW), "rate").strip()
                    # measured on this laptop: 60 Hz and 90 Hz draw the same, 120+ Hz draws ~0.4-0.5 W more, so only drop from 110 Hz and up
                    if base and float(base) >= float(cfg("ADAPTIVE_MIN_HZ", "110")) and float(base) > float(cfg("IDLE_HZ", "60")):
                        LOW.touch(); refresh(); continue            # idle long enough: drop the rate, then wait for input below
                wait = 30.0                                          # busy (audio, call, locked...) or nothing to lower: look again in 30 s
            else:
                # sleep exactly until the earliest moment the idle threshold could be reached (no fixed-rate polling)
                wait = max(2.0, thr - idle_s) if enabled else 3600
            r, _, _ = select.select([i3.stdout], [], [], wait)
            if not r: continue
        # ---- an i3 event: re-evaluate cinema mode (only for fullscreen/close/workspace changes)
        if i3.stdout in r:
            line = i3.stdout.readline()
            if not line: time.sleep(1); continue
            if any(x in line for x in ('"fullscreen_mode"', '"close"', '"current"', '"new"', '"move"')):
                want = cfg("CINEMA", "1") == "1" and cinema_wanted()
                if want and not CIN.exists():
                    CIN.touch(); LOW.unlink(missing_ok=True); CINHZ.unlink(missing_ok=True); refresh()
                    threading.Thread(target=match_fps_later, daemon=True).start()      # mpv: switch to the video's exact multiple
                elif not want and CIN.exists(): CIN.unlink(missing_ok=True); CINHZ.unlink(missing_ok=True); refresh()
                if '"close"' in line or '"new"' in line or '"move"' in line or '"current"' in line:
                    if cfg("WS_ICONS", "0") == "1": sync_icons()

if __name__ == "__main__":
    main()
