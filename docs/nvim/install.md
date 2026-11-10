---
title: "Install and layout"
parent: "Neovim"
nav_order: 1
---

# Install and layout

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


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
