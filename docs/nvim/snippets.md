---
title: "LaTeX snippets"
parent: "Neovim"
nav_order: 8
---

# LaTeX snippets

`lua/utils/snippets.lua` defines a set of LuaSnip snippets for `tex` files, loaded by `lua/plugins/luasnip.lua` after the VS Code style snippet packages. Type the trigger and expand it with LuaSnip's expand key; `i(n)` nodes are the tab stops.

33 triggers: `tex`, `preamble`, `sec`, `ssec`, `sssec`, `bf`, `it`, `ul`, `cite`, `ref`, `mk`, `dm`, `sr`, `cb`, `->`, `ff`, `sqrt`, `sum`, `int`, `binc`, `vec`, `(`, `[`, `{`, `|`, `beg`, `item`, `enum`, `eq`, `ali`, `fig`, `pmat`, `bmat`

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


## What each one produces

| Trigger | Result |
|---|---|
| `preamble` | `\documentclass{article}`, `amsmath`, `graphicx`, `inputenc`, title, the author name from `$USER`, `\date{\today}` and an empty document body |
| `sec` / `ssec` / `sssec` | `\section{name}\label{sec:name}` (and the sub-levels); the label repeats the name through a function node |
| `bf` / `it` / `ul` | `\textbf{}`, `\textit{}`, `\underline{}` |
| `cite` / `ref` | `\cite{key}` / `\ref{label}` |
| `mk` / `dm` | Inline math `$ $` / display math `\[ \]` |
| `sr` / `cb` | `^2` / `^3` |
| `->` | `\to` |
| `ff` | `\frac{num}{den}` |
| `sqrt`, `sum`, `int`, `binc`, `vec` | `\sqrt{}`, `\sum_{i=1}^{n}`, `\int_{a}^{b}`, `\binom{n}{k}`, `\vec{v}` |
| `(`, `[`, `{` and the vertical bar | Auto-sized delimiters: `\left( … \right)` and the other three |
| `beg` | `\begin{env} … \end{env}` with the name copied to the end |
| `item` / `enum` | An `itemize` / `enumerate` environment with one item |
| `eq` / `ali` | `equation` / `align*` environments |
| `fig` | A `figure[htbp]` with centred `includegraphics` at 0.8 text width, caption and label |
| `pmat` / `bmat` | `pmatrix` / `bmatrix` environments |
