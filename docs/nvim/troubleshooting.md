---
title: "Troubleshooting and known issues"
parent: "Neovim"
nav_order: 11
---

# Troubleshooting and known issues

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
