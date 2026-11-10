"""Validate the docs site without Jekyll: front matter, navigation, links, anchors, Liquid hazards, privacy strings, coverage."""
import re, sys
from collections import defaultdict
from pathlib import Path
from common import *

SITE_ROOT = SITE
errors, warns = [], []


def front(p):
    t = p.read_text()
    m = re.match(r"^---\n(.*?)\n---\n", t, re.S)
    if not m:
        return None, t
    try:
        import yaml
        fmv = yaml.safe_load(m.group(1)) or {}
        fmv = {k: (str(v) if v is not None else "") for k, v in fmv.items()}
    except ImportError:
        fmv = {}
        for l in m.group(1).splitlines():
            if ":" in l:
                k, v = l.split(":", 1)
                v = v.strip()
                if not (v.startswith('"') and v.endswith('"')) and ": " in v:
                    errors.append(f"{p.name}: unquoted front matter value contains ': ': {v[:50]}")
                fmv[k.strip()] = v.strip('"')
    except Exception as e:
        errors.append(f"{p.name}: front matter is not valid YAML ({e})")
        fmv = {}
    return fmv, t[m.end():]


def slug(h):
    h = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", h)
    h = re.sub(r"[`*_]", "", h) if False else h.replace("`", "").replace("*", "")
    h = h.lower()
    h = re.sub(r"[^a-z0-9 -]", "", h)
    h = h.replace(" ", "-")
    h = re.sub(r"^[^a-z]+", "", h)
    return h


pages = {}
titles = defaultdict(list)
for p in sorted(SITE_ROOT.rglob("*.md")):
    fmv, body = front(p)
    rel = p.relative_to(SITE_ROOT)
    if fmv is None or "title" not in fmv:
        errors.append(f"{rel}: no front matter or title")
        continue
    pages[rel] = (fmv, body)
    titles[(fmv.get("parent"), fmv["title"])].append(rel)

orders = defaultdict(list)
for rel, (fmv, body) in pages.items():
    if "nav_order" in fmv:
        orders[(fmv.get("parent"), fmv["nav_order"])].append(rel)
for (par, o), rels in orders.items():
    if len(rels) > 1:
        errors.append(f"nav_order {o} is used by several pages under '{par}': {', '.join(map(str, rels))}")
all_titles = {f["title"] for f, _ in pages.values()}
for (par, t), rels in titles.items():
    if len(rels) > 1:
        errors.append(f"duplicate title '{t}' under parent '{par}': {', '.join(map(str, rels))}")
    if par and par not in all_titles:
        errors.append(f"parent '{par}' of '{t}' does not exist")
tops = [t for (par, t) in titles if not par]
for t in tops:
    if sum(1 for (par, tt) in titles if tt == t) > 1:
        errors.append(f"title '{t}' used at top level and elsewhere (just-the-docs needs unique titles per level and not equal to ancestors)")

anchors = {}
for rel, (fmv, body) in pages.items():
    a = set()
    for h in re.findall(r"^#{1,6}\s+(.+?)\s*$", body, re.M):
        a.add(slug(h))
    anchors[rel] = a

link_re = re.compile(r"(?<!\!)\[[^\]]*\]\(([^)\s]+)\)")
img_re = re.compile(r"!\[[^\]]*\]\(([^)\s]+)\)")
for rel, (fmv, body) in pages.items():
    text = re.sub(r"```.*?```", "", body, flags=re.S)
    for target in link_re.findall(text) + img_re.findall(text):
        if target.startswith(("http://", "https://", "mailto:", "#")):
            if target.startswith("#") and slug(target[1:]) != target[1:] and target[1:] not in anchors[rel]:
                warns.append(f"{rel}: anchor {target} not found")
            elif target.startswith("#") and target[1:] not in anchors[rel]:
                warns.append(f"{rel}: anchor {target} not found")
            continue
        path, _, frag = target.partition("#")
        base = (SITE_ROOT / rel).parent
        dest = (base / path).resolve() if path else (SITE_ROOT / rel)
        if not path:
            continue
        cand = None
        if path.endswith("/") or dest.is_dir():
            cand = dest / "index.md"
        elif path.endswith(".html"):
            cand = Path(str(dest)[:-5] + ".md")
        elif dest.suffix in (".png", ".gif", ".jpg", ".svg", ".md"):
            cand = dest
        else:
            cand = Path(str(dest) + ".md")
        if cand is None or not cand.exists():
            errors.append(f"{rel}: broken link {target}")
            continue
        if frag and cand.suffix == ".md":
            r2 = cand.relative_to(SITE_ROOT)
            if r2 in anchors and frag not in anchors[r2]:
                warns.append(f"{rel}: anchor #{frag} not found in {r2}")

# Liquid: a body with {{ or {% must be wrapped in raw
for rel, (fmv, body) in pages.items():
    if ("{{" in body or "{%" in body) and not body.lstrip().startswith("{% raw %}"):
        errors.append(f"{rel}: Liquid syntax outside raw")
    inner = body.replace("{% raw %}", "").replace("{% endraw %}", "")
    if body.lstrip().startswith("{% raw %}") and "{% raw %}" in inner:
        errors.append(f"{rel}: nested raw")

# privacy
import os
_pf = Path(os.environ.get("PRIVACY_FILE", ""))
BAD = [l.strip() for l in _pf.read_text().splitlines() if l.strip()] if _pf.is_file() else [r"100\.\d+\.\d+\.\d+", r"192\.168\.\d+\.\d+", r"BEGIN [A-Z ]*PRIVATE KEY", r"gho_[A-Za-z0-9]{10,}"]
# (my own personal patterns are kept out of the repository in a file that PRIVACY_FILE points to)
for p in SITE_ROOT.rglob("*"):
    if p.is_file() and p.suffix in (".md", ".yml"):
        t = p.read_text()
        for b in BAD:
            for m in re.finditer(b, t):
                errors.append(f"{p.relative_to(SITE_ROOT)}: privacy pattern /{b}/ near '{t[max(0, m.start()-30):m.end()+30]!r}'")

# coverage: every script of the repos is mentioned in some page body besides the file index
allbody = "\n".join(b for f, b in pages.values() if True)
for f in sorted((DOTS / "scripts").glob("*")):
    if f.name not in allbody:
        errors.append(f"script {f.name} is not mentioned in any page")
for f in sorted((DOTS / "rog-tune").glob("*.sh")):
    if f.name not in allbody:
        errors.append(f"rog-tune/{f.name} is not mentioned")
for f in sorted((DOTS / "iso").glob("*")):
    if f.is_file() and f.name not in allbody and f.name not in ("README.md",):
        errors.append(f"iso/{f.name} is not mentioned")
for f in sorted((NVIM / "lua/plugins").glob("*.lua")):
    if f.name not in allbody:
        errors.append(f"nvim plugin file {f.name} is not mentioned")
for f in (HYPR / "conf").glob("*.lua"):
    if f.name not in allbody:
        errors.append(f"hypr conf/{f.name} is not mentioned")
for f in sorted((HYPR / "scripts").glob("*")):
    if f.is_file() and f.suffix != ".pyc" and f.name not in allbody:
        errors.append(f"hypr scripts/{f.name} is not mentioned")
for f in sorted((HYPR / "system").glob("*")):
    if f.name not in allbody:
        errors.append(f"hypr system/{f.name} is not mentioned")

print(f"{len(pages)} pages, {len(errors)} errors, {len(warns)} warnings")
for e in errors:
    print("ERROR", e)
for w in warns[:60]:
    print("warn ", w)
sys.exit(1 if errors else 0)
