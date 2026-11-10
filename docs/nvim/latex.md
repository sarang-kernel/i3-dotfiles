---
title: "LaTeX"
parent: "Neovim"
nav_order: 7
---

# LaTeX

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


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
