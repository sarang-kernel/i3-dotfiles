---
title: "Language servers, formatting and diagnostics"
parent: "Neovim"
nav_order: 5
---

# Language servers, formatting and diagnostics

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


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
