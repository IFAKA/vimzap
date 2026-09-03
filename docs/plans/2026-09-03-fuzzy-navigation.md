# Fuzzy Navigation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement the plan task-by-task.

**Goal:** Route the remaining high-value navigation actions through VimZap's fuzzy picker.

**Architecture:** Keep `mini.pick` as the single picker implementation. Reuse its built-in help picker and its `vim.ui.select` override for generated lists, while preserving direct terminal workflows for interactive Git status.

**Tech Stack:** Neovim 0.12 Lua APIs, `mini.pick`, native LSP and diagnostics.

---

### Task 1: Add fuzzy navigation actions

**Files:**
- Modify: `lua/keymaps.lua`

Add fuzzy help, commands, keymaps, Git commits, and diagnostics actions. Keep file, grep, buffer, recent-file, and Git status behavior intact.

### Task 2: Align documentation

**Files:**
- Modify: `README.md`

Document the expanded fuzzy workflows and correct the commit mapping.

### Task 3: Verify and ship

Run `bash tests/smoke.sh`, inspect the diff, explicitly stage changed files, commit without amending, and push `main` to `origin`. Reinstall using the repository installer in update mode and verify the installed configuration loads.
