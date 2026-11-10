"""Generated pages for rog-tune: every 'part' of rog-tune.sh and rog-lean-session.sh with its description and the files it writes."""
import re
from common import *

TUNE = DOTS / "rog-tune/rog-tune.sh"
LEAN = DOTS / "rog-tune/rog-lean-session.sh"


def parse_parts(path, start_re, indent_cont):
    """Header lines: '#   name   description' then continuation lines indented further."""
    parts, cur = [], None
    for line in read(path).splitlines()[:80]:
        if not line.startswith("#"):
            if parts:
                break
            continue
        m = re.match(r"^#\s{2,3}([a-z0-9_]+)\s+(.*)$", line)
        if m and not line.startswith("#       "):
            cur = [m.group(1), m.group(2).strip()]
            parts.append(cur)
            continue
        m = re.match(r"^#\s{%d,}(.*)$" % indent_cont, line)
        if m and cur:
            cur[1] += " " + m.group(1).strip()
    return [(n, d) for n, d in parts if n not in ("parts", "sudo")]


def tune_files():
    """For each part: the files it creates with new_file, and other absolute paths it edits."""
    files = {}
    cur = []
    for line in read(TUNE).splitlines():
        m = re.match(r"^has (\w+) && new_file (\S+)", line)
        if m:
            files.setdefault(m.group(1), []).append(m.group(2))
            continue
        m = re.match(r"^if (has .*); then", line)
        if m:
            cur = re.findall(r"has (\w+)", m.group(1))
            continue
        if line == "fi":
            cur = []
            continue
        for mm in re.finditer(r"new_file (/[A-Za-z0-9_./-]+)", line):
            for c in cur:
                files.setdefault(c, []).append(mm.group(1))
        for mm in re.finditer(r"\$R(/(?:etc|usr|var|boot)/[A-Za-z0-9_./-]+)", line):
            for c in cur:
                p = mm.group(1)
                if p not in files.get(c, []) and not p.startswith("/var/backups/rog-tune"):
                    files.setdefault(c, []).append(p)
    return {k: sorted(set(v)) for k, v in files.items()}


def build():
    parts = parse_parts(TUNE, None, 9)
    files = tune_files()
    hdr = header_block(str(TUNE))
    usage = "\n".join(l for l in hdr[:5])
    body = ["`rog-tune.sh` holds every **root-side** change I made to the ROG Flow X13: power saving, boot options, the login screen, hibernation, package-manager hooks, services. "
            "It is organised as *parts*: each part is a self-contained, named change.\n\n"
            "```text\n" + usage + "\n```\n\n"
            "Three rules make it safe to run on the machine I live on:\n\n"
            "1. **Dry run by default.** Without `--apply` it prints every change as a diff and touches nothing.\n"
            "2. **Backups.** `--apply` copies every file it is about to change into `/var/backups/rog-tune/<timestamp>/files` and records a `manifest` and the list of `parts`.\n"
            "3. **`--undo`** restores the most recent backup: files go back (or are removed if they did not exist before) and the part-specific side effects are reversed (units re-enabled, sysctl reloaded, the NVIDIA runtime power setting turned back on, GRUB config regenerated and so on).\n\n"
            "With no parts given it runs `gpu sysctl journal`. Every other part is **opt-in**; the table says which ones I actually applied is *not* tracked here, because `--undo` and the dry run are the source of truth on the machine. "
            "Set `ROG_ROOT` (a test root) and `ROG_SYSFS` to try a part against a scratch directory: in that mode `live` only prints what it would run.\n", TOC,
            f"\n## The {len(parts)} parts\n\nDescriptions are the header of the script, verbatim. *Writes* lists the files the script creates or edits for that part (extracted from the code).\n"]
    for n, d in parts:
        body.append(f"\n### `{n}`\n\n{d}\n")
        if files.get(n):
            body.append("\n**Writes:** " + ", ".join(f"`{f}`" for f in files[n]) + "\n")
    body.append("\n## Running it\n\n```bash\nsudo ~/rog-tune/rog-tune.sh                       # dry run of the default parts\nsudo ~/rog-tune/rog-tune.sh --apply greetd hibernate   # apply some parts\nsudo ~/rog-tune/rog-tune.sh --undo                # put the last backup back\n```\n")
    body.append("\n## Parts that are retired\n\n`slimboot` refuses to run: it removed the `amdgpu` driver from the boot image, which let the greetd login screen race the GPU driver at boot. `amdgpu` is back in the boot image (`MODULES=(amdgpu)` in `mkinitcpio.conf`) and the greeter start script waits for the driver. See [Changes](../changes/).\n")
    write("rog-tune/rog-tune-parts.md", fm("rog-tune.sh parts", "rog-tune", 1), "# `rog-tune.sh`: the root-side parts\n\n" + "\n".join(body))

    lparts = parse_parts(LEAN, None, 9)
    hdr = header_block(str(LEAN))
    usage = "\n".join(hdr[:5])
    body = ["`rog-lean-session.sh` is the **user-side** sibling: no sudo, it edits files in my home folder (`i3/config`, `polybar/config.ini`, `kitty.conf`, `.bashrc`, autostart entries) and **writes out the helper scripts** that live in `~/.config/scripts`. "
            "Almost every feature of the desktop was added as one of its parts.\n\n```text\n" + usage + "\n```\n\n"
            "It follows the same discipline as `rog-tune.sh`: dry run by default, `--apply` to change things, `--undo` to restore. Before changing a file it copies it to `~/.local/share/rog-tune/<name>.before`; lines it adds are tagged with the marker `rog-tune` "
            "(that is why so many comments in my configs start with `# rog-tune:`), so a part can find its own lines and a second run does not duplicate them. `created.list` remembers files it created so `--undo` can remove them.\n\n"
            "Two things to know:\n\n"
            "- The scripts are **embedded** in this installer as here-documents (that is why it is 4000+ lines long). The repo's `scripts/` copies are the live files; `embsync.py` in the ISO tooling keeps the embedded copies and the live ones in step. "
            "If you edit a live script, remember the installer would write the older embedded copy next time it runs that part.\n"
            "- Parts that are left out of `ALL` (the default) need an explicit request: `picom`, `hz60`, `vaapi`, `psd` (profile-sync-daemon, costs about 2 GB of RAM) and a few retired ones.\n", TOC, f"\n## The {len(lparts)} parts\n"]
    for n, d in lparts:
        body.append(f"\n### `{n}`\n\n{d}\n")
    body.append("\n## Undo\n\n`~/rog-tune/rog-lean-session.sh --undo` restores i3 config, polybar, kitty, `.bashrc`, picom config, rofi themes, wallpaper scripts and the lock script from the `.before` copies, deletes the autostart stubs it made, removes the lines it added to Firefox/Zen `user.js`, "
                "disables `psd` and `dunst` masking if it did those, and re-enables the broken automount if it had disabled it. Then log out and in (or `i3-msg restart`).\n")
    write("rog-tune/lean-session-parts.md", fm("rog-lean-session.sh parts", "rog-tune", 2), "# `rog-lean-session.sh`: the user-side parts\n\n" + "\n".join(body))
    return len(parts), len(lparts)


if __name__ == "__main__":
    print(build())
