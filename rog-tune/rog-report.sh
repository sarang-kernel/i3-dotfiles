#!/usr/bin/env bash
# What is this machine spending? Run it before and after a change and compare.
#   ~/rog-tune/rog-report.sh [seconds]      default 30; reads /proc and /sys only (it never wakes the dGPU)
exec python3 - "${1:-30}" <<'P'
import collections, glob, os, sys, time
HZ = os.sysconf("SC_CLK_TCK"); N = os.cpu_count(); secs = int(sys.argv[1])
def snap():
    d = {}
    for p in os.listdir("/proc"):
        if not p.isdigit(): continue
        try:
            f = open(f"/proc/{p}/stat").read().rsplit(")", 1)
            comm = f[0].split("(", 1)[1]; x = f[1].split()
            pss = 0
            for l in open(f"/proc/{p}/smaps_rollup"):
                if l.startswith("Pss:"): pss = int(l.split()[1]); break
            d[int(p)] = (comm, int(x[11]) + int(x[12]), pss, int(x[1]))
        except (OSError, IndexError, ValueError): pass
    return d
a = snap(); t0 = time.monotonic(); time.sleep(secs); b = snap(); dt = time.monotonic() - t0
cpu = {p: (b[p][1] - a[p][1]) / HZ / dt * 100 for p in b if p in a}
def app(p):
    # an app is the root of its process tree under the session: group Chromium/Electron helpers with their parent
    seen = set()
    while p in b and p not in seen:
        seen.add(p); pp = b[p][3]
        if pp <= 1 or pp not in b or b[pp][0] in ("systemd", "i3", "lightdm", "sshd-session", "bash", "sh", "kitty"): break
        p = pp
    c = b[p][0]
    try:
        cl = open(f"/proc/{p}/cmdline").read().split("\0")
        if c == "electron" and len(cl) > 1 and not cl[1].startswith("--"): c = os.path.basename(cl[1].rstrip("/")) or c
    except OSError: pass
    return c
g = collections.defaultdict(lambda: [0.0, 0.0, 0])
for p in b:
    k = app(p); g[k][0] += cpu.get(p, 0); g[k][1] += b[p][2] / 1024; g[k][2] += 1
print(f"== {secs}s sample · machine {sum(cpu.values())/N:.1f}% busy ({sum(cpu.values()):.0f}% of one core, {N} threads)")
print(f"   {'CPU(1 core)':>11} {'RAM MB':>8} {'procs':>5}  app")
for k, (c, m, n) in sorted(g.items(), key=lambda kv: -(kv[1][0] * 100 + kv[1][1]))[:8]:
    print(f"   {c:10.1f}% {m:8.0f} {n:5d}  {k}")
def rd(p, default="?"):
    try: return open(p).read().strip()
    except OSError: return default
print("== dGPU (RTX) power state, from sysfs")
for d in sorted(glob.glob("/sys/bus/pci/devices/*")):
    if rd(d + "/vendor") == "0x10de" and rd(d + "/class").startswith("0x03"):
        act, sus = int(rd(d + "/power/runtime_active_time", "0")), int(rd(d + "/power/runtime_suspended_time", "0"))
        print(f"   {os.path.basename(d)} control={rd(d+'/power/control')} status={rd(d+'/power/runtime_status')} suspended {sus/1000:.0f}s of {(act+sus)/1000:.0f}s")
print("== heat and fans")
for h in sorted(glob.glob("/sys/class/hwmon/hwmon*")):
    n = rd(h + "/name"); out = []
    for f in sorted(glob.glob(h + "/fan*_input")): out.append(f"{rd(f.replace('_input','_label'), os.path.basename(f))} {rd(f)} RPM")
    if n in ("k10temp", "amdgpu", "nvme"):
        t = rd(h + "/temp1_input", "0"); out.append(f"{int(t)//1000} °C")
    if out: print(f"   {n}: " + ", ".join(out))
for z in sorted(glob.glob("/sys/class/thermal/thermal_zone*")):
    t = int(rd(z + "/temp", "0")) // 1000
    if t > 25: print(f"   {rd(z+'/type')} ({os.path.basename(z)}): {t} °C")
print("== display / cpu")
try:
    import subprocess
    x = subprocess.run(["xrandr", "--query"], capture_output=True, text=True, env={**os.environ, "DISPLAY": os.environ.get("DISPLAY", ":0")}).stdout
    for l in x.splitlines():
        if "*" in l: print("   mode: " + " ".join(l.split()[:2]) + "  (* = current)")
except OSError: pass
fr = [int(rd(f, "0")) for f in glob.glob("/sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq")]
print(f"   average CPU clock {sum(fr)/max(len(fr),1)/1000:.0f} MHz · profile {rd('/sys/firmware/acpi/platform_profile')} · governor {rd('/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor')}")
P
