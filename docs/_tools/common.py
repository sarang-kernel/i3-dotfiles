"""Shared helpers for the docs generator: paths, front matter, Liquid-safe output."""
import os, re
from pathlib import Path

S = Path(os.environ.get("DOCS_WORK", Path.home() / "docs-work"))     # working folder: src/<repo copies>, imgs/, site/ (output)
SRC = S / "src"
DOTS = SRC / "i3-dotfiles"
SPOT = SRC / "spotlight"
NVIM = SRC / "nvim"
ISO = SRC / "rog-iso"
HYPR = Path.home() / ".config/hypr"
DASH = Path.home() / ".local/share/hp-dash"
SITE = S / "site"

TOC = ('<details open markdown="block">\n  <summary>On this page</summary>\n  {: .text-delta }\n1. TOC\n{:toc}\n</details>\n')


def fm(title, parent=None, order=None, children=False, grand=None, desc=None):
    q = lambda v: '"' + str(v).replace("\\", "\\\\").replace('"', '\\"') + '"'
    lines = ["---", f"title: {q(title)}"]
    if parent:
        lines.append(f"parent: {q(parent)}")
    if grand:
        lines.append(f"grand_parent: {q(grand)}")
    if order is not None:
        lines.append(f"nav_order: {order}")
    if children:
        lines.append("has_children: true")
    if desc:
        lines.append(f"description: {q(desc)}")
    lines.append("---")
    return "\n".join(lines) + "\n\n"


def liquid_safe(body):
    """Jekyll evaluates {{ }} and {% %} even inside code fences: wrap the whole body in raw tags when it contains them."""
    if "{{" in body or "{%" in body:
        body = body.replace("{% raw %}", "").replace("{% endraw %}", "")
        return "{% raw %}\n" + body + "\n{% endraw %}\n"
    return body


def write(rel, front, body):
    p = SITE / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(front + liquid_safe(body))
    return p


def read(p):
    return Path(p).read_text(errors="replace")


def md_escape_cell(s):
    return str(s).replace("|", "\\|").replace("\n", " ")


def table(headers, rows):
    out = ["| " + " | ".join(headers) + " |", "|" + "|".join("---" for _ in headers) + "|"]
    for r in rows:
        out.append("| " + " | ".join(md_escape_cell(c) for c in r) + " |")
    return "\n".join(out) + "\n"


def header_block(path, maxlines=60):
    """The leading comment block of a script (after the shebang), comment markers stripped."""
    out = []
    for i, line in enumerate(read(path).splitlines()):
        if i == 0 and line.startswith("#!"):
            continue
        if line.startswith("#") or line.startswith("--") and path.endswith(".lua"):
            out.append(re.sub(r"^(#|--)\s?", "", line).rstrip())
        elif line.strip() == "" and not out:
            continue
        else:
            break
        if len(out) >= maxlines:
            break
    return out


def py_docstring_or_header(path):
    txt = read(path)
    m = re.match(r'(?:#!.*\n)?(?:#.*\n)*\s*"""(.*?)"""', txt, re.S)
    if m:
        return [l.rstrip() for l in m.group(1).strip().splitlines()]
    return header_block(path)
