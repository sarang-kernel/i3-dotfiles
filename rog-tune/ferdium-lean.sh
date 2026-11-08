#!/usr/bin/env bash
# Trim Ferdium's idle cost. Changes only settings, not my services or logins, and keeps a backup.
#   ~/rog-tune/ferdium-lean.sh            show what would change (Ferdium may be running)
#   ~/rog-tune/ferdium-lean.sh --apply    do it; refuses while Ferdium is running, because it rewrites this file on exit
#   ~/rog-tune/ferdium-lean.sh --undo     put the backup back
set -euo pipefail
F=${FERDIUM_SETTINGS:-$HOME/.config/Ferdium/config/settings.json}
[[ -f $F ]] || { echo "no Ferdium settings at $F" >&2; exit 1; }
running() { pgrep -f '^/usr/lib/electron[0-9]*/electron /opt/ferdium' >/dev/null; }
python3 -I - "$F" "${1:-}" "${FERDIUM_FAKE_RUNNING:-0}" <<'P'
import json, os, shutil, subprocess, sys, time
f, mode, fake = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
bk = f + ".before-lean"
if mode == "--undo":
    shutil.copy2(bk, f); print("restored", bk); sys.exit(0)
d = json.load(open(f))
# why each: spellcheck loads dictionaries into every service page; the todo panel keeps a web page ready; sentry is
# telemetry; hibernation unloads a service after this many seconds idle (it wakes every wakeUpStrategy seconds to
# fetch notifications, so messages still arrive)
want = {"enableSpellchecking": False, "isTodosFeatureEnabled": False, "sentry": False, "hibernationStrategy": 120}
changes = {k: (d.get(k), v) for k, v in want.items() if d.get(k) != v}
if not changes:
    print("already lean"); sys.exit(0)
for k, (a, b) in changes.items(): print(f"  {k}: {a} -> {b}")
if mode != "--apply":
    print("dry run: nothing changed (run with --apply after closing Ferdium)"); sys.exit(0)
alive = fake or subprocess.run(["pgrep", "-f", r"^/usr/lib/electron[0-9]*/electron /opt/ferdium"]).returncode == 0
if alive:
    print("Ferdium is running: close it first (it would overwrite these settings on exit)"); sys.exit(1)
shutil.copy2(f, bk)
d.update(want)
tmp = f + ".tmp"; json.dump(d, open(tmp, "w"), indent=2); os.replace(tmp, f)
print("done; backup at", bk, "(undo: --undo)")
P
