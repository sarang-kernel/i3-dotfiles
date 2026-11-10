---
title: "Git and debugging"
parent: "Neovim"
nav_order: 9
---

# Git and debugging

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


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
