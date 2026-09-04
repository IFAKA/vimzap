# Native Developer Workflow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a project-aware native task runner so VimZap can discover and run npm scripts, capture output, and navigate failures like an IDE.

**Architecture:** Keep process execution in Neovim's native `vim.system`, task discovery in a small pure Lua module, and output navigation in the native quickfix list. Avoid a general task plugin until this foundation proves insufficient. The existing focused plugins remain responsible for fuzzy navigation, Git UI, debugging, and SFCC-specific behavior.

**Tech Stack:** Neovim 0.12 Lua APIs, `vim.json`, `vim.system`, quickfix, `vim.ui.select`, shell/npm scripts.

---

### Task 1: Add task discovery and execution module

**Files:**
- Create: `lua/vimzap/tasks.lua`
- Test: `tests/tasks.lua`

**Step 1: Write the failing test**

Add assertions for locating the project root, decoding package scripts, and constructing an npm command.

**Step 2: Run test to verify it fails**

Run: `nvim --headless -u NONE --cmd 'set rtp+=.' -l tests/tasks.lua`
Expected: FAIL because `vimzap.tasks` does not exist.

**Step 3: Write minimal implementation**

Implement pure discovery helpers plus native asynchronous execution. Discover `package.json` scripts and expose a task picker; send output to a scratch terminal-style buffer and parse common compiler output into quickfix.

**Step 4: Run test to verify it passes**

Run: `nvim --headless -u NONE --cmd 'set rtp+=.' -l tests/tasks.lua`
Expected: PASS.

### Task 2: Wire developer-facing commands and keymaps

**Files:**
- Modify: `lua/keymaps.lua`
- Modify: `lua/vimzap/dashboard.lua`
- Modify: `README.md`

**Step 1: Add failing smoke assertions**

Assert the task module, commands, and Run keymap group are present.

**Step 2: Implement the integration**

Add `<Space>r r` to select a project task, `<Space>r l` to rerun the last task, `<Space>r q` to open task quickfix, and dashboard access. Add `:VimZapTasks`, `:VimZapTask`, `:VimZapTaskLast`, and `:VimZapTaskQuickfix`.

**Step 3: Run focused and repository checks**

Run the task unit test and `bash tests/smoke.sh`.

### Task 3: Verify real npm workflow

**Files:**
- No production files unless verification exposes a defect.

**Step 1: Exercise discovery in a temporary package project**

Use a temporary directory containing `package.json` scripts and run the headless task discovery test.

**Step 2: Exercise VimZap startup**

Run Neovim headlessly with the repository configuration and confirm no startup error, then inspect the diff for unrelated changes.

**Step 3: Document tradeoffs**

Document why native tasks are used now, and record Overseer and Neotest as future optional additions if task orchestration or per-test discovery becomes necessary.
