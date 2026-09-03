# Mostly Native Neovim Setup Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Reduce VimZap's plugin surface while preserving LSP, Git, debugging, Prophet, terminal, and useful navigation workflows.

**Architecture:** Keep Neovim's native LSP client, completion, diagnostics, terminal, package manager, and `vim.ui.select`. Replace `mini.pick`, Conform, Mason, and Mini Comment with small native helpers or direct built-in commands. Retain plugins that provide functionality Neovim does not provide: Git signs, DAP, and Prophet.

**Tech Stack:** Neovim 0.12 Lua APIs, `vim.pack`, native LSP completion, `vim.ui.select`, gitsigns.nvim, nvim-dap, nvim-dap-ui, prophet.nvim.

---

### Task 1: Replace picker and formatter dependencies

**Files:**
- Modify: `lua/keymaps.lua`
- Modify: `lua/vimzap/dashboard.lua`

Implement native file, buffer, recent-file, help, command, diagnostic, symbol, and Git workflows using `vim.ui.select`, `vim.fn.globpath`, built-in LSP commands, and terminal commands. Replace Conform formatting with `vim.lsp.buf.format()` and remove Mini Comment mappings.

### Task 2: Remove optional plugin setup and automatic downloads

**Files:**
- Modify: `lua/plugins.lua`

Keep only lspconfig, gitsigns, DAP dependencies, and Prophet. Remove Mason setup, PATH mutation, automatic Mason installation, Conform setup, and Mini Comment setup.

### Task 3: Align documentation with the native setup

**Files:**
- Modify: `README.md`

Document native picker behavior and manual installation of language servers/formatters/debug adapters. Remove references to Mason, Mini Comment, and Conform.

### Task 4: Verify configuration syntax and dependency references

Run Lua syntax checks, search for removed dependency references, and inspect the final diff. If an installed Neovim binary is available, run headless startup and health checks.
