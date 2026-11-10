"""Generated pages for the Neovim section: keymaps, plugins, snippets, LSP servers. Parsed from the Lua files and lazy-lock.json."""
import json, re
from common import *

LUA = NVIM / "lua"

PLUG = {
    "lazy.nvim": ("Plugin manager", "Bootstrapped by `init.lua` (cloned on first start, branch `stable`). `:Lazy` opens its UI; `lazy-lock.json` pins every commit."),
    "catppuccin": ("Colour scheme", "Mocha flavour with a transparent background, integrations for cmp, gitsigns, neo-tree, treesitter, telescope and native LSP (diagnostics are undercurled)."),
    "alpha-nvim": ("Start screen", "The dashboard: Find file, New file, Recent files, Find text, Config, Quit, and my pixel cat with *Meow Meow* underneath."),
    "nvim-web-devicons": ("File icons", "Needed by neo-tree, telescope, lualine and alpha. Needs a Nerd Font in the terminal."),
    "lualine.nvim": ("Status line", "Dracula theme (the Catppuccin theme line is commented out)."),
    "neo-tree.nvim": ("File explorer", "Branch `v3.x`, 30 columns wide. `<leader>e` toggles it; `<leader>+` / `<leader>-` resize it."),
    "nui.nvim": ("UI components", "Dependency of neo-tree."),
    "plenary.nvim": ("Lua helpers", "Dependency of telescope and neo-tree."),
    "snacks.nvim": ("Utility collection", "Dependency of neo-tree (image support)."),
    "image.nvim": ("Inline images", "Shows images in neo-tree previews. Prints *cannot query terminal size* when Neovim runs without a terminal (for example headless)."),
    "telescope.nvim": ("Fuzzy finder", "Tag 0.1.8. `<leader>ff` files, `<leader>fg` live grep, `<leader>fb` buffers, `<leader>fh` help."),
    "telescope-ui-select.nvim": ("Telescope as the picker for `vim.ui.select`", "Code actions and other menus show up in a dropdown."),
    "nvim-treesitter": ("Syntax highlighting and indent", "`auto_install = true`: a parser is downloaded the first time a language is opened. Needs `tree-sitter-cli` and a C compiler."),
    "nvim-lspconfig": ("LSP client configs", "Servers are configured with the new `vim.lsp.config()` / `vim.lsp.enable()` API (Neovim 0.11+)."),
    "mason.nvim": ("Installer for language servers and tools", "`:Mason` opens its UI; binaries live in `~/.local/share/nvim/mason/bin`."),
    "mason-lspconfig.nvim": ("Mason ⇄ lspconfig bridge", "`ensure_installed` makes sure 14 servers exist, with `automatic_installation = true`."),
    "mason-null-ls.nvim": ("Mason ⇄ none-ls bridge", "Installs the formatters and linters none-ls uses."),
    "none-ls.nvim": ("Formatters and linters as an LSP", "stylua, prettier, shfmt and black format on save; markdownlint and yamllint lint; a spell completion source."),
    "nvim-autopairs": ("Auto-close brackets and quotes", "Treesitter-aware (`check_ts`) with per-language rules."),
    "nvim-ts-autotag": ("Auto-close and rename HTML/XML tags", "For html, xml, jsx and tsx files."),
    "gitsigns.nvim": ("Git signs in the gutter", "Hunk navigation, stage, reset, preview and blame; see Git keymaps."),
    "nvim-dap": ("Debug adapter protocol client", "Breakpoints and stepping."),
    "nvim-dap-ui": ("Debugger UI", "Opens on launch/attach, closes on exit."),
    "nvim-dap-go": ("Go debugging helper", "Delve adapter configuration."),
    "nvim-nio": ("Async library", "Dependency of nvim-dap-ui."),
    "LuaSnip": ("Snippet engine", "Loads VS Code style snippets from friendly-snippets and my own LaTeX snippets (`utils/snippets.lua`)."),
    "friendly-snippets": ("Snippet collection", "Ready-made snippets for many languages."),
    "which-key.nvim": ("Shows pending keybindings", "`<leader>?` lists the buffer-local keymaps."),
    "render-markdown": ("Pretty Markdown in the buffer", "Headings, tables, code blocks, callouts, links (with special icons for GitHub, arXiv, YouTube and more) and Obsidian-style `[[wiki links]]`."),
    "vimtex": ("LaTeX", "latexmk by default, view in zathura, conceal on; keys start with `,`."),
}


FALLBACK = {"K": "Hover documentation (LSP)", "gd": "Go to definition (LSP)", "<leader>ca": "Code actions (LSP)", "<leader>gf": "Format the buffer (LSP)",
            "gf": "Markdown only: follow the [[wiki link]] under the cursor (opens ~/notes/NAME.md, creating it if needed)",
            ",ll": "VimTeX: compile", ",lv": "VimTeX: view the PDF", ",lk": "VimTeX: stop the compiler/viewer", ",le": "VimTeX: show errors",
            ",lc": "VimTeX: clean build files", ",li": "VimTeX: info"}


def call_text(live, start):
    """Text of the call whose opening parenthesis is just before `start` (balanced, string-aware enough for this config)."""
    depth, i, instr = 1, start, None
    while i < len(live) and depth:
        c = live[i]
        if instr:
            if c == "\\":
                i += 1
            elif c == instr:
                instr = None
        elif c in "\"'":
            instr = c
        elif c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
        i += 1
    return live[start:i]


def parse_keymaps():
    rows = []
    for f in sorted(LUA.rglob("*.lua")):
        t = read(f)
        live = "\n".join(l for l in t.splitlines() if not l.strip().startswith("--"))
        for m in re.finditer(r"(?:vim\.keymap\.set|\bmap)\(\s*(\{[^}]*\}|\"[^\"]*\")\s*,\s*\"([^\"]+)\"\s*,", live):
            mode = m.group(1).replace('"', "").replace("{", "").replace("}", "").replace(" ", "")
            lhs = m.group(2)
            body = call_text(live, m.end())
            d = re.search(r'desc\s*=\s*"([^"]+)"', body)
            desc = d.group(1) if d else ""
            if not desc:
                d2 = re.search(r',\s*"([A-Za-z][^"]{3,60})"\s*$', body.rstrip(") \n"))
                desc = d2.group(1) if d2 else ""
            if not desc:
                desc = FALLBACK.get(lhs, "")
            rows.append((mode, lhs, desc, str(f.relative_to(NVIM))))
    rows.append(("n", "<leader>?", "Buffer Local Keymaps (which-key)", "lua/plugins/which-key.lua"))
    return rows


def parse_snippets():
    t = read(LUA / "utils/snippets.lua")
    return re.findall(r's\("([^"]+)",', t)


def build():
    km = parse_keymaps()
    seen, rows = set(), []
    for mode, lhs, desc, f in km:
        k = (mode, lhs, f)
        if k in seen:
            continue
        seen.add(k)
        dead = lhs in ("]c", "[c", "<leader>hs", "<leader>hr", "<leader>hP", "<leader>hb")
        rows.append((f"`{lhs}`", mode, (desc or "(see the file)") + (" **(not active, see below)**" if dead else ""), f"`{f}`"))
    rows.sort(key=lambda r: (r[3], r[0]))
    body = ["The leader key is **Space**; the local leader is `//`, and VimTeX uses `,`. This table is generated by reading the keymap definitions in my Lua files, so it lists exactly what is defined. "
            "Plugin defaults (Telescope's insert-mode keys, Neo-tree's own mappings, `gc` comments, Neovim's built-ins) are not listed because I did not define them; `:Telescope keymaps` or `<leader>?` shows everything that is live.\n",
            TOC, "\n## Every keymap I define\n\nMode: `n` normal, `i` insert, `v` visual. Buffer-local maps (git hunks, Markdown `gf`) exist only in the buffers they are made for.\n\n",
            table(["Key", "Mode", "What it does", "Defined in"], rows),
            "\n## Handy built-ins I rely on\n\n" + table(["Key", "What it does"], [
                ("`gcc` / `gc` + motion", "Comment a line / a motion (Neovim 0.10+ built-in)"),
                ("`K`", "Hover documentation (mapped to `vim.lsp.buf.hover`)"),
                ("`gd`", "Go to definition (mapped to `vim.lsp.buf.definition`)"),
                ("`:Lazy`, `:Mason`, `:checkhealth`", "Plugin manager, tool installer, diagnosis"),
                ("`:Neotree`", "File tree (my `<leader>e` is `:Neotree toggle reveal_force_cwd`)"),
                ("`:Telescope`", "Pickers; `:Telescope keymaps` lists every live keymap"),
            ])]
    body.append("\n## Things worth knowing\n\n"
                "- `<leader>gf` is defined **twice**: in `vim-options.lua` (`vim.lsp.buf.format`) and again in `none-ls.lua` (`vim.lsp.buf.format({ async = true })`). The later definition (none-ls, loaded lazily on file open) wins once a file is open.\n"
                "- `gf` on a Markdown file is remapped for `[[wiki links]]`: it opens `~/notes/<link>.md` (creating it if it does not exist). The README note about `gf` as file-under-cursor applies to every other filetype.\n"
                "- **The git keymaps are not active.** `]c`, `[c`, `<leader>hs`, `<leader>hr`, `<leader>hP` and `<leader>hb` are written inside `M.setup_gitsigns_keymaps(bufnr)` in `vim-options.lua`, but nothing ever calls that function (`gitsigns.lua` has no `on_attach`). I checked in a headless session: `maparg(\"<leader>hs\", \"n\")` is empty in a git file. The signs in the gutter work; the hunk keys do not. The fix is one line: `on_attach = require(\"vim-options\").setup_gitsigns_keymaps` in the gitsigns options. The README table that lists them describes the intention, not the current state.\n"
                "- The debug keymaps (`<leader>d…`) are registered by `nvim-dap-ui`'s config, so they appear once that plugin has loaded.\n")
    write("nvim/keymaps.md", fm("Keymaps", "Neovim", 3, desc="Every keymap defined in the config"), "# Keymaps\n\n" + "\n".join(body))

    lock = json.loads(read(NVIM / "lazy-lock.json"))
    prow = []
    for name in sorted(lock, key=str.lower):
        kind, note = PLUG.get(name, ("(undocumented)", ""))
        prow.append((f"`{name}`", kind, note, f"`{lock[name]['branch']}`", f"`{lock[name]['commit'][:7]}`"))
    body = [f"{len(lock)} plugins, all pinned in `lazy-lock.json`. Generated from the lock file; the descriptions are mine.\n", TOC, "\n## The plugins\n\n",
            table(["Plugin", "What it is", "How I use it", "Branch", "Pinned commit"], prow),
            "\n## Which files load them\n\nOne spec per file in `lua/plugins/`; `lazy.setup(\"plugins\")` imports the whole folder. `lua/plugins.lua` is an empty `return {}` left over from the first version.\n\n"
            + table(["File", "Plugins"], [(f"`lua/plugins/{f.name}`", ", ".join(sorted(set(re.findall(r'"([A-Za-z0-9_.\-]+/[A-Za-z0-9_.\-]+)"', "\n".join(l for l in read(f).splitlines() if not l.strip().startswith('--'))))))[:200]) for f in sorted((LUA / "plugins").glob("*.lua"))]),
            "\n### Disabled on purpose\n\n`completions.lua` starts with `local enable_completion = false` and returns an empty spec: nvim-cmp, cmp-nvim-lsp and cmp_luasnip are *not loaded* (their entries are in the file, ready to switch on). "
            "That is why there is no completion popup today even though LuaSnip and friendly-snippets are installed. Flip the flag to `true` to get the popup (`<C-Space>` completes, `<CR>` confirms, `<C-b>`/`<C-f>` scroll docs, `<C-e>` aborts).\n"]
    write("nvim/plugins.md", fm("Plugins", "Neovim", 4), "# Plugins\n\n" + "\n".join(body))

    sn = parse_snippets()
    write("nvim/snippets.md", fm("LaTeX snippets", "Neovim", 8), "# LaTeX snippets\n\n" + "\n".join([
        "`lua/utils/snippets.lua` defines a set of LuaSnip snippets for `tex` files, loaded by `lua/plugins/luasnip.lua` after the VS Code style snippet packages. "
        "Type the trigger and expand it with LuaSnip's expand key; `i(n)` nodes are the tab stops.\n",
        f"{len(sn)} triggers: " + ", ".join(f"`{x}`" for x in sn) + "\n", TOC,
        "\n## What each one produces\n\n" + table(["Trigger", "Result"], [
            ("`preamble`", "`\\documentclass{article}`, `amsmath`, `graphicx`, `inputenc`, title, the author name from `$USER`, `\\date{\\today}` and an empty document body"),
            ("`sec` / `ssec` / `sssec`", "`\\section{name}\\label{sec:name}` (and the sub-levels); the label repeats the name through a function node"),
            ("`bf` / `it` / `ul`", "`\\textbf{}`, `\\textit{}`, `\\underline{}`"),
            ("`cite` / `ref`", "`\\cite{key}` / `\\ref{label}`"),
            ("`mk` / `dm`", "Inline math `$ $` / display math `\\[ \\]`"),
            ("`sr` / `cb`", "`^2` / `^3`"),
            ("`->`", "`\\to`"),
            ("`ff`", "`\\frac{num}{den}`"),
            ("`sqrt`, `sum`, `int`, `binc`, `vec`", "`\\sqrt{}`, `\\sum_{i=1}^{n}`, `\\int_{a}^{b}`, `\\binom{n}{k}`, `\\vec{v}`"),
            ("`(`, `[`, `{` and the vertical bar", "Auto-sized delimiters: `\\left( … \\right)` and the other three"),
            ("`beg`", "`\\begin{env} … \\end{env}` with the name copied to the end"),
            ("`item` / `enum`", "An `itemize` / `enumerate` environment with one item"),
            ("`eq` / `ali`", "`equation` / `align*` environments"),
            ("`fig`", "A `figure[htbp]` with centred `includegraphics` at 0.8 text width, caption and label"),
            ("`pmat` / `bmat`", "`pmatrix` / `bmatrix` environments"),
        ])]))
    return len(rows), len(lock), len(sn)


if __name__ == "__main__":
    print(build())
