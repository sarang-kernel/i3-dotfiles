---
title: "Plugins"
parent: "Neovim"
nav_order: 4
---

# Plugins

30 plugins, all pinned in `lazy-lock.json`. Generated from the lock file; the descriptions are mine.

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


## The plugins


| Plugin | What it is | How I use it | Branch | Pinned commit |
|---|---|---|---|---|
| `alpha-nvim` | Start screen | The dashboard: Find file, New file, Recent files, Find text, Config, Quit, and my pixel cat with *Meow Meow* underneath. | `main` | `7563da4` |
| `catppuccin` | Colour scheme | Mocha flavour with a transparent background, integrations for cmp, gitsigns, neo-tree, treesitter, telescope and native LSP (diagnostics are undercurled). | `main` | `426dbeb` |
| `friendly-snippets` | Snippet collection | Ready-made snippets for many languages. | `main` | `6cd7280` |
| `gitsigns.nvim` | Git signs in the gutter | Hunk navigation, stage, reset, preview and blame; see Git keymaps. | `main` | `8d82c24` |
| `image.nvim` | Inline images | Shows images in neo-tree previews. Prints *cannot query terminal size* when Neovim runs without a terminal (for example headless). | `master` | `da2be65` |
| `lazy.nvim` | Plugin manager | Bootstrapped by `init.lua` (cloned on first start, branch `stable`). `:Lazy` opens its UI; `lazy-lock.json` pins every commit. | `main` | `306a055` |
| `lualine.nvim` | Status line | Dracula theme (the Catppuccin theme line is commented out). | `master` | `a905eee` |
| `LuaSnip` | Snippet engine | Loads VS Code style snippets from friendly-snippets and my own LaTeX snippets (`utils/snippets.lua`). | `master` | `a62e108` |
| `mason-lspconfig.nvim` | Mason ⇄ lspconfig bridge | `ensure_installed` makes sure 14 servers exist, with `automatic_installation = true`. | `main` | `0a3b42c` |
| `mason-null-ls.nvim` | Mason ⇄ none-ls bridge | Installs the formatters and linters none-ls uses. | `main` | `8e7806a` |
| `mason.nvim` | Installer for language servers and tools | `:Mason` opens its UI; binaries live in `~/.local/share/nvim/mason/bin`. | `main` | `b03fb0f` |
| `neo-tree.nvim` | File explorer | Branch `v3.x`, 30 columns wide. `<leader>e` toggles it; `<leader>+` / `<leader>-` resize it. | `v3.x` | `84c75e7` |
| `none-ls.nvim` | Formatters and linters as an LSP | stylua, prettier, shfmt and black format on save; markdownlint and yamllint lint; a spell completion source. | `main` | `899e93f` |
| `nui.nvim` | UI components | Dependency of neo-tree. | `main` | `de74099` |
| `nvim-autopairs` | Auto-close brackets and quotes | Treesitter-aware (`check_ts`) with per-language rules. | `master` | `59bce2e` |
| `nvim-dap` | Debug adapter protocol client | Breakpoints and stepping. | `master` | `45a69eb` |
| `nvim-dap-go` | Go debugging helper | Delve adapter configuration. | `main` | `b442115` |
| `nvim-dap-ui` | Debugger UI | Opens on launch/attach, closes on exit. | `master` | `1a66cab` |
| `nvim-lspconfig` | LSP client configs | Servers are configured with the new `vim.lsp.config()` / `vim.lsp.enable()` API (Neovim 0.11+). | `master` | `b80f82f` |
| `nvim-nio` | Async library | Dependency of nvim-dap-ui. | `master` | `21f5324` |
| `nvim-treesitter` | Syntax highlighting and indent | `auto_install = true`: a parser is downloaded the first time a language is opened. Needs `tree-sitter-cli` and a C compiler. | `main` | `4916d65` |
| `nvim-ts-autotag` | Auto-close and rename HTML/XML tags | For html, xml, jsx and tsx files. | `main` | `88c1453` |
| `nvim-web-devicons` | File icons | Needed by neo-tree, telescope, lualine and alpha. Needs a Nerd Font in the terminal. | `master` | `c72328a` |
| `plenary.nvim` | Lua helpers | Dependency of telescope and neo-tree. | `master` | `74b06c6` |
| `render-markdown` | Pretty Markdown in the buffer | Headings, tables, code blocks, callouts, links (with special icons for GitHub, arXiv, YouTube and more) and Obsidian-style `[[wiki links]]`. | `main` | `0fd43fb` |
| `snacks.nvim` | Utility collection | Dependency of neo-tree (image support). | `main` | `ad9ede6` |
| `telescope-ui-select.nvim` | Telescope as the picker for `vim.ui.select` | Code actions and other menus show up in a dropdown. | `master` | `6e51d7d` |
| `telescope.nvim` | Fuzzy finder | Tag 0.1.8. `<leader>ff` files, `<leader>fg` live grep, `<leader>fb` buffers, `<leader>fh` help. | `master` | `a0bbec2` |
| `vimtex` | LaTeX | latexmk by default, view in zathura, conceal on; keys start with `,`. | `master` | `9306903` |
| `which-key.nvim` | Shows pending keybindings | `<leader>?` lists the buffer-local keymaps. | `main` | `3aab214` |


## Which files load them

One spec per file in `lua/plugins/`; `lazy.setup("plugins")` imports the whole folder. `lua/plugins.lua` is an empty `return {}` left over from the first version.

| File | Plugins |
|---|---|
| `lua/plugins/alpha.lua` | goolord/alpha-nvim, nvim-tree/nvim-web-devicons |
| `lua/plugins/autopairs.lua` | windwp/nvim-autopairs, windwp/nvim-ts-autotag |
| `lua/plugins/catppuccin.lua` | catppuccin/nvim |
| `lua/plugins/completions.lua` | L3MON4D3/LuaSnip, hrsh7th/cmp-nvim-lsp, hrsh7th/nvim-cmp, rafamadriz/friendly-snippets, saadparwaiz1/cmp_luasnip |
| `lua/plugins/debugging.lua` | leoluz/nvim-dap-go, mfussenegger/nvim-dap, nvim-neotest/nvim-nio, rcarriga/nvim-dap-ui |
| `lua/plugins/gitsigns.lua` | lewis6991/gitsigns.nvim |
| `lua/plugins/latex.lua` | lervag/vimtex, neovim/nvim-lspconfig, nvim-treesitter/nvim-treesitter, rafamadriz/friendly-snippets |
| `lua/plugins/lsp-config.lua` | mason-org/mason-lspconfig.nvim, mason-org/mason.nvim, neovim/nvim-lspconfig |
| `lua/plugins/lualine.lua` |  |
| `lua/plugins/luasnip.lua` | L3MON4D3/LuaSnip, rafamadriz/friendly-snippets |
| `lua/plugins/neo-tree.lua` | 3rd/image.nvim, MunifTanjim/nui.nvim, folke/snacks.nvim, nvim-lua/plenary.nvim, nvim-neo-tree/neo-tree.nvim, nvim-tree/nvim-web-devicons |
| `lua/plugins/none-ls.lua` | jay-babu/mason-null-ls.nvim, nvimtools/none-ls.nvim, textDocument/formatting |
| `lua/plugins/render-markdown.lua` | MeanderingProgrammer/render-markdown.nvim, N/A, nvim-treesitter/nvim-treesitter |
| `lua/plugins/telescope.lua` | nvim-lua/plenary.nvim, nvim-telescope/telescope-ui-select.nvim, nvim-telescope/telescope.nvim, nvim-treesitter/nvim-treesitter |
| `lua/plugins/treesitter.lua` | nvim-treesitter/nvim-treesitter |
| `lua/plugins/which-key.lua` | folke/which-key.nvim |


### Disabled on purpose

`completions.lua` starts with `local enable_completion = false` and returns an empty spec: nvim-cmp, cmp-nvim-lsp and cmp_luasnip are *not loaded* (their entries are in the file, ready to switch on). That is why there is no completion popup today even though LuaSnip and friendly-snippets are installed. Flip the flag to `true` to get the popup (`<C-Space>` completes, `<CR>` confirms, `<C-b>`/`<C-f>` scroll docs, `<C-e>` aborts).
