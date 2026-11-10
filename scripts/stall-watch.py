#!/usr/bin/env python3
"""stall-watch: catches the "lags once in a while" moments. Passive and tiny (about 0.1% CPU).
Every 100 ms it sleeps and checks how late it woke up; a late wake-up means the whole machine stalled (CPU starved, disk blocked, memory
reclaim, a frozen kernel path). It also watches the kernel's pressure counters. When something stalls for more than THRESH seconds
it writes one line: time, how long, which of CPU/IO/memory was starved, the busiest processes, and the current CPU frequency and display
refresh rate. Look at the log with:  stall-watch.py report
"""
import os, sys, time, subprocess, pathlib, collections

LOG = pathlib.Path(os.environ.get("XDG_STATE_HOME", pathlib.Path.home() / ".local/state")) / "stall-watch" / "stalls.log"
THRESH = 0.20          # seconds late before it counts as a stall
MAXLINES = 5000


def psi():
    out = {}
    for k in ("cpu", "io", "memory"):
        try:
            for line in open(f"/proc/pressure/{k}"):
                p = line.split()
                if p[0] == "some":
                    out[k] = int(p[4].split("=")[1])      # total microseconds
        except OSError:
            pass
    return out


def top_procs():
    try:
        r = subprocess.run(["ps", "-eo", "pcpu,stat,comm", "--sort=-pcpu", "--no-headers"],
                           capture_output=True, text=True, timeout=2).stdout.splitlines()
        busy = [" ".join(l.split(None, 2)) for l in r[:3]]
        d = [l.split(None, 2)[2] for l in r if l.split(None, 2)[1].startswith("D")][:3]
        return "top: " + "; ".join(busy) + ("  blocked(D): " + ",".join(d) if d else "")
    except Exception:
        return ""


def cpu_mhz():
    try:
        return int(open("/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq").read()) // 1000
    except OSError:
        return -1


def refresh():
    if not os.environ.get("DISPLAY"):
        return ""
    try:
        o = subprocess.run(["xrandr", "--current"], capture_output=True, text=True, timeout=2).stdout
        for l in o.splitlines():
            if "*" in l:
                return l.split()[1] if len(l.split()) > 1 else ""
    except Exception:
        pass
    return ""


def trim():
    try:
        lines = LOG.read_text().splitlines()
        if len(lines) > MAXLINES:
            LOG.write_text("\n".join(lines[-MAXLINES // 2:]) + "\n")
    except OSError:
        pass


def report():
    if not LOG.exists():
        print("no stalls recorded yet")
        return
    lines = LOG.read_text().splitlines()
    print(f"{len(lines)} lines logged. Last 25:")
    print("\n".join(lines[-25:]))
    hours = collections.Counter(l[11:13] for l in lines)
    print("\nlines per hour of day:", dict(sorted(hours.items())))


def watch():
    LOG.parent.mkdir(parents=True, exist_ok=True)
    prev = psi()
    last_hz = refresh()
    n = 0
    while True:
        t0 = time.monotonic()
        time.sleep(0.1)
        late = time.monotonic() - t0 - 0.1
        n += 1
        hz = refresh() if n % 50 == 0 else last_hz
        if hz != last_hz:
            with LOG.open("a") as f:
                f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')}  refresh rate changed {last_hz} -> {hz}\n")
            last_hz = hz
        if late >= THRESH:
            cur = psi()
            starved = ",".join(f"{k}+{(cur[k]-prev.get(k,0))/1000:.0f}ms" for k in cur if cur[k] - prev.get(k, 0) > 20000)
            with LOG.open("a") as f:
                f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')}  stall {late*1000:.0f}ms  starved[{starved or 'none'}]  "
                        f"{cpu_mhz()}MHz  {last_hz}  {top_procs()}\n")
        if n % 100 == 0:
            prev = psi()
        if n % 5000 == 0:
            trim()


if __name__ == "__main__":
    report() if sys.argv[1:] == ["report"] else watch()
