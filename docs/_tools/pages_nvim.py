"""Hand-written pages of the Neovim section."""
from common import *

P = "Neovim"


def build():
    write("nvim/index.md", fm(P, None, 7, children=True, desc="My Neovim configuration"),
          """# Neovim

My Neovim setup: **lazy.nvim**, 30 plugins, the Catppuccin Mocha theme with a transparent background, LSP for 14 languages through Mason, format-on-save, Telescope, Neo-tree, a debugger, an excellent Markdown renderer and a LaTeX workflow.
It lives in its own repo: [`sarang-kernel/nvim`](https://github.com/sarang-kernel/nvim) (MIT licence), and is included in my dotfiles as a git submodule.

![The editor with Neo-tree](../img/editor.png)

## Pages

| Page | What you get |
|---|---|
| [Install and layout](install.html) | Requirements, first start, what each file is |
| [Keymaps](keymaps.html) | Every keymap I define, generated from the Lua files |
| [Plugins](plugins.html) | All 30 plugins with the pinned commit, and what I use each for |
| [Language servers, formatting and diagnostics](lsp-format.html) | Mason, the servers, none-ls, format on save |
| [Markdown](markdown.html) | render-markdown and my `[[wiki link]]` navigation |
| [LaTeX](latex.html) | VimTeX with latexmk and zathura, and the snippets |
| [LaTeX snippets](snippets.html) | Every snippet trigger |
| [Git and debugging](git-debug.html) | gitsigns and nvim-dap |
| [Customising](customising.html) | How to change things safely |
| [Troubleshooting and known issues](troubleshooting.html) | Including two things that are documented but not wired up |

## The shape of it

```text
~/.config/nvim/
  init.lua              bootstraps lazy.nvim, loads vim-options, calls lazy.setup("plugins"), loads alpha
  lua/vim-options.lua   options, leader keys, general keymaps, and helper functions other files call
  lua/plugins/*.lua     one lazy.nvim spec per file (16 files)
  lua/utils/snippets.lua   my LaTeX snippets
  lazy-lock.json        the pinned plugin commits
  README.md  LICENSE
```
""")

    write("nvim/install.md", fm("Install and layout", P, 1), """# Install and layout

{TOC}

## Requirements

- **Neovim 0.11 or newer.** The config uses `vim.lsp.config()` / `vim.lsp.enable()` and `vim.fs.root`. I run 0.12.
- `git` (lazy.nvim clones plugins), a **C compiler** and the **`tree-sitter-cli`** (treesitter builds parsers), **Node.js** (several Mason packages need it), `ripgrep` (Telescope's live grep), a **Nerd Font** in the terminal (icons in neo-tree, lualine, alpha).
- Optional: `zathura` (the PDF viewer VimTeX is configured for), `latexmk` and a TeX distribution (LaTeX), `lazygit` is *not* used.

## First start

```bash
git clone https://github.com/sarang-kernel/nvim ~/.config/nvim
nvim
```

`init.lua` clones lazy.nvim into `~/.local/share/nvim/lazy/lazy.nvim` (branch `stable`) if it is missing, and exits with the git error if that fails. lazy.nvim then installs the plugins listed in `lazy-lock.json` at their pinned commits, Mason installs the language servers and tools (`:Mason` shows progress), and treesitter downloads a parser the first time you open each language.
Check health with `:checkhealth`. (My `:checkhealth` shows only harmless warnings about filetypes such as `markdown.mdx` and `yaml.docker-compose`.)

## What each file does

| File | What it does |
|---|---|
| `init.lua` | Bootstraps lazy.nvim, prepends it to the runtime path, `require("vim-options")`, `require("lazy").setup("plugins")` (loads every file in `lua/plugins`), then `require("alpha")` |
| `lua/vim-options.lua` | `expandtab`, `tabstop=2`, `softtabstop=2`, `shiftwidth=2`, `number`; leader = Space, local leader = `//`; the general keymaps; window navigation; Neo-tree toggle and resizing; LSP `K`, `gd`, `<leader>ca`; `<leader>gf`; and a module table `M` with `setup_dap_keymaps`, `get_cmp_mappings` and `setup_gitsigns_keymaps` that other files call (or should) |
| `lua/plugins.lua` | `return {}`: empty, left from an earlier layout |
| `lua/plugins/*.lua` | One spec per file: `alpha`, `autopairs`, `catppuccin`, `completions` (disabled), `debugging`, `gitsigns`, `latex`, `lsp-config`, `lualine`, `luasnip`, `neo-tree`, `none-ls`, `render-markdown`, `telescope`, `treesitter`, `which-key` |
| `lua/utils/snippets.lua` | Loaded by `luasnip.lua`: the LaTeX snippets |
| `lazy-lock.json` | Pinned commits (30 plugins). `:Lazy restore` goes back to them; `:Lazy update` moves them forward |

## Options that are *not* set

No `relativenumber`, no `clipboard=unnamedplus` (use `"+y`), no `scrolloff`, no `ignorecase`/`smartcase`, `timeoutlen` stays 1000 ms. The status line is lualine with the Dracula theme; the start screen is alpha.

## Updating

`:Lazy sync` (install, clean, update). Commit the changed `lazy-lock.json` to keep the pins in step with what works.
""".replace("{TOC}", TOC))

    write("nvim/lsp-format.md", fm("Language servers, formatting and diagnostics", P, 5), """# Language servers, formatting and diagnostics

{TOC}

## Mason and the servers

`mason.nvim` installs binaries into `~/.local/share/nvim/mason/bin`. `mason-lspconfig.nvim` has `ensure_installed` for **14 servers** and `automatic_installation = true`:

| Server | Language |
|---|---|
| `lua_ls` | Lua (configured specially, see below) |
| `pyright` | Python |
| `ts_ls` | TypeScript and JavaScript |
| `html`, `cssls` | HTML, CSS |
| `bashls` | Bash |
| `clangd` | C and C++ |
| `rust_analyzer` | Rust |
| `jsonls`, `yamlls`, `taplo` | JSON, YAML, TOML |
| `marksman` | Markdown |
| `dockerls` | Dockerfiles |
| `texlab` | LaTeX |

The config then enables 13 of them explicitly with the **Neovim 0.11 API**: a `servers` table (`pyright ts_ls html cssls bashls clangd rust_analyzer jsonls yamlls dockerls taplo texlab`) is looped through `vim.lsp.config(name, { capabilities = … })` and `vim.lsp.enable(name)`. `marksman` is installed but is not in that table; whether it attaches depends on mason-lspconfig's automatic enabling.

**`lua_ls`** gets its own block: LuaJIT runtime, `diagnostics.globals = { "vim" }`, the whole Neovim runtime as the workspace library, `checkThirdParty = false`, telemetry off, root markers `.git`, `.luarc.json(c)`, `.luacheckrc`, `lua`.

**Capabilities** come from `cmp_nvim_lsp` when it is loaded (it is not, while completion is disabled), otherwise the default client capabilities.

## Diagnostics

`vim.diagnostic.config`: virtual text on, signs on, underline on, no updates while typing in insert mode, severity-sorted. **Diagnostics are switched off in Markdown buffers** (a `FileType` autocommand disables them for the buffer, because prose triggers noise).

## LSP keymaps

`K` hover, `gd` go to definition, `<leader>ca` code actions, `<leader>gf` format. See [Keymaps](keymaps.html).

## Formatting and linting: none-ls

`none-ls.nvim` makes external tools look like an LSP server. It loads on `BufReadPre`/`BufNewFile`.

| Role | Tools active |
|---|---|
| Formatters | `stylua` (Lua), `prettier` (JS, TS, CSS, HTML), `shfmt` (shell), `black` (Python) |
| Diagnostics | `markdownlint`, `yamllint` |
| Completion | `spell` |
| Present but commented out | `eslint_d`, `flake8`, `shellcheck` diagnostics (their binaries are still installed by Mason) |

**Format on save:** in `on_attach`, for any client that supports `textDocument/formatting`, a `BufWritePre` autocommand in the group `LspFormatting` calls `vim.lsp.buf.format({ bufnr })`. That is why saving a Lua, Python or shell file reformats it, and why a language server that can format (for example `lua_ls` without stylua) may also take part. `mason-null-ls` installs the tools (scheduled with `vim.schedule` and `pcall`, to avoid a race at startup).

`<leader>gf` formats on demand (asynchronously through none-ls).

## Adding a language

1. Add its server to `ensure_installed` in `lsp-config.lua` and to the `servers` table.
2. If it needs a formatter, add the tool to `none-ls.lua` (`sources`) and to `mason-null-ls`'s `ensure_installed`.
3. `:Mason` to confirm the install, `:LspInfo` (or `:checkhealth vim.lsp`) to confirm it attached.
""".replace("{TOC}", TOC))

    write("nvim/markdown.md", fm("Markdown", P, 6), """# Markdown

{TOC}

![Markdown rendered inside Neovim](../img/markdown.png)

`render-markdown.nvim` (loaded for `markdown` files) draws Markdown **inside the buffer** while you edit: numbered headings with icons and coloured bars, tables with borders, checkboxes, quotes, code blocks, horizontal rules, links with icons, and callouts. Moving the cursor onto a line shows the raw text again. Diagnostics are off in Markdown buffers (see [LSP](lsp-format.html#diagnostics)); `marksman` provides links and symbols if it is attached.

## Headings and links

- Headings use six numbered icons (`󰎤 󰎧 󰎪 󰎭 󰎱 󰎳`), rendered inline.
- Links are rendered with icons: images, e-mail, hyperlinks and footnotes (superscript), plus **custom icons by site**: web (`^http`), GitHub, GitLab, Stack Overflow, Wikipedia, YouTube, arXiv, WolframAlpha, Overleaf, crates.io, docs.rs, PyPI, npm, DevDocs, MDN, OWASP, PortSwigger and the CVE database.
- Everything else (callouts, checkboxes, bullets, code, inline code, tables, dashes, quotes) uses the plugin's defaults; the config says so in a comment ("rest of your callouts … all unchanged").

## `[[wiki links]]` for my notes

My notes (an Obsidian vault) live in `~/notes`. Obsidian-style links are understood:

- `[[Page]]` and `[[Page|alias]]` are rendered with an icon; the **body** shows the file size and how long ago `~/notes/Page.md` was modified (for example `󱗖 1.2KB | 󰥔 3d ago | Page`), or `󰅖 Missing: Page` when there is no such file.
- **`gf`** (in Markdown buffers only) on a link opens `~/notes/<name>.md` and **creates it if it does not exist**, so a link becomes a new note in one keystroke. The alias part after `|` is ignored.

The helper functions `format_size` and `format_time_ago` (bytes → `B/KB/MB`, seconds → `now`, `Nm ago`, `Nh ago`, `Nd ago`) are at the top of `render-markdown.lua`.

## Lint

`markdownlint` is configured as a none-ls diagnostics source, but diagnostics are **disabled in Markdown buffers** (`lsp-config.lua`), so its messages are never shown while editing a `.md` file. To see them, delete the `FileType markdown` autocommand that calls `vim.diagnostic.enable(false, { bufnr = 0 })`.
""".replace("{TOC}", TOC))

    write("nvim/latex.md", fm("LaTeX", P, 7), """# LaTeX

{TOC}

`lua/plugins/latex.lua` is an Overleaf-like setup. It contains the current spec and, above it, an older commented-out version (v4) kept for reference.

## The spec

| Piece | Config |
|---|---|
| **VimTeX** (`lervag/vimtex`, filetypes `tex`, `latex`, `bib`) | Local leader `,`; viewer **zathura**; compiler **latexmk** with `-pdf -interaction=nonstopmode -synctex=1`; conceal on |
| **Optional compiler** | A commented block switches to **tectonic** (single pass, fast, keeps some hyperref warnings) |
| **LSP** | `texlab` through `nvim-lspconfig` |
| **Treesitter** | Adds the `latex` parser to `ensure_installed` |
| **Snippets** | `friendly-snippets` plus my own [LaTeX snippets](snippets.html) |

## Keys

The mappings are explicit (`<Cmd>` forms) rather than VimTeX's own, so they work even if the plugin's mappings are not loaded:

| Key | Command | What it does |
|---|---|---|
| `,ll` | `:VimtexCompile` | Start or stop continuous compilation |
| `,lv` | `:VimtexView` | Open the PDF (forward search with synctex) |
| `,lk` | `:VimtexStop` | Stop the compiler/viewer |
| `,le` | `:VimtexErrors` | Show errors |
| `,lc` | `:VimtexClean` | Remove build files |
| `,li` | `:VimtexInfo` | Show the VimTeX state |

## Needs

A TeX distribution with `latexmk`, `zathura` with the poppler plugin (it is deliberately *not* in my restore ISO; reinstall it with `sudo pacman -S zathura zathura-pdf-poppler`), and the `texlab` server (Mason).
""".replace("{TOC}", TOC))

    write("nvim/git-debug.md", fm("Git and debugging", P, 9), """# Git and debugging

{TOC}

## gitsigns

`gitsigns.nvim` loads on `BufReadPre`/`BufNewFile`. Signs: `│` add and change, `_` delete, `‾` top delete, `~` change-delete, `┆` untracked. `watch_gitdir.follow_files = true`, `current_line_blame = false` (no inline blame).

**Known issue: the hunk keymaps are not active.** The README and `vim-options.lua` describe `]c`, `[c`, `<leader>hs` (stage hunk), `<leader>hr` (reset hunk), `<leader>hP` (preview hunk) and `<leader>hb` (blame line), but they are only defined inside `M.setup_gitsigns_keymaps(bufnr)`, and nothing calls that function. To activate them, pass it as `on_attach` in `lua/plugins/gitsigns.lua`:

```lua
opts = {
  -- …
  on_attach = require("vim-options").setup_gitsigns_keymaps,
}
```

You can still use the commands: `:Gitsigns stage_hunk`, `:Gitsigns reset_hunk`, `:Gitsigns preview_hunk`, `:Gitsigns blame_line`, `:Gitsigns next_hunk`.

## nvim-dap

`nvim-dap`, `nvim-dap-ui` (with `nvim-nio`) and `nvim-dap-go`. The UI opens automatically when a session is launched or attached (`dap.listeners.before.attach/launch`) and closes when it terminates or exits. `require("dap-go").setup()` configures the Delve adapter, so **Go is the only language with a debug adapter configured**; other languages need an adapter (and configuration) added in `debugging.lua`.

| Key | What it does |
|---|---|
| `<Leader>db` | Toggle breakpoint |
| `<Leader>dc` | Continue |
| `<Leader>do` | Step over |
| `<Leader>di` | Step into |
| `<Leader>du` | Step out |

These are registered by `debugging.lua` through `require("vim-options").setup_dap_keymaps()` when `nvim-dap-ui`'s config runs (checked: `<leader>db` is live in a headless start).
""".replace("{TOC}", TOC))

    write("nvim/customising.md", fm("Customising", P, 10), """# Customising

{TOC}

## Turn completion on

`lua/plugins/completions.lua` starts with `local enable_completion = false`. Set it to `true`. The popup uses `luasnip` as the first source and the buffer as the second (`nvim_lsp` is commented out in `sources`, so LSP completions do not appear until you uncomment it). Keys: `<C-Space>` complete, `<C-b>`/`<C-f>` scroll the docs, `<C-e>` abort, `<CR>` confirm, and the preset insert mappings (`<C-n>`/`<C-p>`, `<Tab>` is **not** mapped by the config; the README mentions it for the cmp preset).

## Change the colours

`catppuccin.lua`: `flavour = "mocha"` (`latte`, `frappe`, `macchiato`), `transparent_background = true` so the terminal's translucency shows. lualine's theme is separate (`dracula`; the `catppuccin` line is commented in `lualine.lua`).

## Add a plugin

Create `lua/plugins/<name>.lua` returning a spec (`return { "owner/repo", opts = {} }`). lazy.nvim picks it up on the next start (`:Lazy` to install). Commit `lazy-lock.json` afterwards.

## Add keymaps

Put general keymaps in `vim-options.lua`; plugin-specific ones in the plugin's own file. Always give a `desc` so `<leader>?` (which-key) and `:Telescope keymaps` explain them.

## Change the start screen

`alpha.lua`: the pixel-cat header, the six buttons (`f`, `n`, `r`, `g`, `c`, `q`), the footer text (*Meow Meow*) and the highlight groups.

## Move the notes folder

The Markdown wiki-link logic uses `~/notes/`. It appears twice in `render-markdown.lua` (the link body and the `gf` mapping).

## Pin or roll back plugins

`:Lazy restore` installs the commits in `lazy-lock.json`. `:Lazy update` moves everything; if something breaks, `git checkout lazy-lock.json` followed by `:Lazy restore` undoes it.
""".replace("{TOC}", TOC))

    write("nvim/troubleshooting.md", fm("Troubleshooting and known issues", P, 11), """# Troubleshooting and known issues

## Known issues (found while documenting)

| Issue | Detail | Fix |
|---|---|---|
| Git hunk keymaps are not active | `]c`, `[c`, `<leader>hs/hr/hP/hb` are defined inside a function that is never called | See [Git and debugging](git-debug.html#gitsigns) |
| Completion is disabled | `enable_completion = false` in `completions.lua`, although the README has a section on nvim-cmp | See [Customising](customising.html#turn-completion-on) |
| `<leader>gf` is defined twice | `vim-options.lua` (sync `vim.lsp.buf.format`) and `none-ls.lua` (async); the later wins once a file is open | Delete one of them |
| `<leader>h` has a short delay | It clears search highlight but has no longer map today (the hunk maps are not wired), so it fires at once; **if** the hunk maps are enabled, Neovim will wait `timeoutlen` after it | Rename one of them |
| `lua/plugins.lua` is an empty file | Leftover | Harmless |
| The README describes `<Tab>` / `<S-Tab>` for completion | Not mapped by the config | Add to the cmp mapping when enabling completion |
| `latex.lua` contains an old copy of itself in comments | Kept for reference | Delete if you like |

## Symptoms

| Symptom | Cause and fix |
|---|---|
| `image.nvim: cannot query terminal size` | You ran `nvim --headless` or a non-terminal; harmless |
| Treesitter errors on first open of a language | The parser is being built: needs `tree-sitter-cli` and a C compiler; `:checkhealth nvim-treesitter` |
| A language server is missing | `:Mason`; check it is installed, then `:LspInfo` |
| Icons show as boxes | The terminal font is not a Nerd Font |
| `:checkhealth` warns *Unknown filetype 'markdown.mdx'* and similar | A harmless warning from the treesitter health check (filetype aliases) |
| Saving reformats unexpectedly | Format-on-save via none-ls ([LSP page](lsp-format.html#formatting-and-linting-none-ls)); remove the `BufWritePre` autocommand to stop it |
| The PDF never opens from LaTeX | zathura is not installed (it is left out of the restore ISO) |
| Plugins out of step after a pull | `:Lazy restore` |
""")


if __name__ == "__main__":
    build()
