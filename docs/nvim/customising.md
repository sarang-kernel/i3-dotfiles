---
title: "Customising"
parent: "Neovim"
nav_order: 10
---

# Customising

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


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
