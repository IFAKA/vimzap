# Neovim 0.12 Migration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make VimZap a Neovim 0.12-only configuration that uses native plugin management, LSP activation, completion, and plain described keymaps while preserving the existing editing, SFCC, and debugging workflows.

**Architecture:** `vim.pack` becomes the sole plugin installation and loading path, while Mason remains only for third-party language-server, formatter, and debug-adapter binaries that Neovim does not install. Native LSP completion and insert completion replace nvim-cmp, with SFCC candidates exposed as a native completion source. Key groups become `vim.keymap.set()` descriptions discoverable through Snacks' keymap picker.

**Tech Stack:** Neovim 0.12 Lua API, `vim.pack`, native LSP/completion, Bash installer, GitHub Actions smoke tests.

---

### Task 1: Add migration smoke assertions

**Files:**
- Modify: `.github/workflows/test.yml`

**Steps:**
1. Change the tested minimum Neovim version to 0.12.
2. Remove manual plugin-cloning setup and obsolete Vimscript detector copies.
3. Add headless assertions for native package registration, completion options, keymaps, and Lua filetype detection.
4. Run the relevant assertions against the current tree and confirm they fail for the expected legacy behavior.

### Task 2: Move plugin lifecycle to `vim.pack`

**Files:**
- Modify: `lua/plugins.lua`
- Modify: `lua/debug.lua`
- Modify: `lua/benchmark.lua`
- Modify: `i`

**Steps:**
1. Declare all retained plugins with canonical GitHub sources in one `vim.pack.add()` call.
2. Delete explicit `:packadd` calls and handwritten plugin clone/update loops.
3. Retain Mason only for external executable installation.
4. Update benchmark plugin discovery for the native `core/opt` package directory and `vim.pack` state.
5. Validate clean native installation and startup.

### Task 3: Replace cmp and which-key with Neovim 0.12 behavior

**Files:**
- Modify: `lua/lsp.lua`
- Modify: `lua/options.lua`
- Modify: `lua/keymaps.lua`
- Modify: `lua/sfcc.lua`

**Steps:**
1. Remove cmp capabilities and enable native LSP completion on `LspAttach`.
2. Configure native automatic completion and popup navigation mappings.
3. Convert SFCC candidates into a native complete-function source.
4. Convert the which-key registration tree into plain `vim.keymap.set()` calls with descriptions.
5. Remove the redundant manual LSP `FileType` attach autocmd.
6. Run focused headless keymap, filetype, and completion assertions.

### Task 4: Remove compatibility duplication and align diagnostics/docs

**Files:**
- Delete: `ftdetect/ds.vim`
- Delete: `ftdetect/isml.vim`
- Modify: `lua/options.lua`
- Modify: `lua/health.lua`
- Modify: `README.md`
- Modify: `CHANGELOG.md`

**Steps:**
1. Delete duplicate Vimscript filetype detectors and explicit `syntax enable`.
2. Require Neovim 0.12 in installer, health checks, CI, and documentation.
3. Update health reporting for native package management/completion while retaining executable checks.
4. Document `:packupdate`, native completion controls, and Mason's reduced role.
5. Run shell syntax/lint checks and full headless smoke validation.

### Task 5: Final verification

**Files:**
- Inspect all changed files.

**Steps:**
1. Run `bash -n i` and `shellcheck i` when available.
2. Start VimZap headlessly with isolated config/data directories.
3. Assert native package, LSP config, keymap, filetype, and syntax behavior.
4. Review the complete diff and confirm no unrelated files changed.
