# Vanilla-First VimZap Reduction Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Reduce VimZap to native Neovim plus only the DAP and SFCC capability plugins while preserving navigation, Git, tasks, LSP, debugging, and Prophet workflows.

**Architecture:** Replace MiniPick and which-key with small native Lua helpers based on `vim.ui.select`, `vim.fs`, and `vim.system`. Replace Gitsigns commands with native Git/quickfix workflows; retain `nvim-dap`, its `nvim-nio` dependency, and `prophet.nvim` because they implement protocols or SFCC behavior Neovim does not provide.

**Tech Stack:** Neovim 0.12 Lua APIs, `vim.pack`, `vim.ui.select`, `vim.system`, Git CLI, Bash installer, shell smoke tests.

---

### Task 1: Inspect repository state and companion dotfiles

**Files:** No production changes.

Run repository status checks, inspect local instructions, identify how dotfiles references VimZap, and preserve unrelated user changes.

### Task 2: Add native navigation helpers

**Files:**
- Modify: `lua/keymaps.lua`
- Modify: `lua/vimzap/dashboard.lua`

Implement native file, grep, buffer, recent-file, help, command, diagnostic, and Git commit selection using `vim.ui.select`, `vim.fs`, and `vim.system`. Keep argv arrays for subprocesses and avoid shell interpolation.

### Task 3: Remove nonessential plugins and Git UI dependency

**Files:**
- Modify: `lua/plugins.lua`
- Modify: `lua/keymaps.lua`
- Modify: `nvim-pack-lock.json`

Retain only DAP, `nvim-nio`, DAP UI, and Prophet. Remove MiniPick, which-key setup, and Gitsigns mappings. Provide native Git status, diff, blame, and hunk-oriented fallback commands where practical.

### Task 4: Simplify installer dependencies and documentation

**Files:**
- Modify: `i`
- Modify: `README.md`
- Modify: `tests/smoke.sh`

Stop installing unused `fzf` and `lazygit`, document native navigation and the remaining capability plugins, and update smoke assertions to match the reduced dependency surface.

### Task 5: Verify VimZap

Run Lua syntax checks, task tests, smoke tests, headless startup, and inspect the explicit diff. Fix any regressions with new commits rather than amending.

### Task 6: Update and push dotfiles

Inspect the dotfiles VimZap source/reference, update it to the new VimZap commit or current source as appropriate, run its focused checks, commit explicitly listed files, and push without force.

### Task 7: Reinstall dotfiles locally

Run the repository’s documented reinstall command after confirming its target and behavior. Verify the installed Neovim version/config and report any warnings or failures.
