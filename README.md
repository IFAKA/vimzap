<img width="1280" height="640" alt="image" src="https://github.com/user-attachments/assets/938952ac-ebfc-40c3-850e-ee798d8339df" />

# VimZap

Fast Neovim with fuzzy finding, LSP, git, formatting, debugging, and SFCC tooling.

**Requirements:** Neovim 0.12+

## Install

```bash
bash <(curl -fsSL ifaka.github.io/vimzap/i)
```

Use `nvim` to open Neovim. `nvim path/to/file:80` opens that file at line 80.

When Neovim starts without a file, VimZap opens a native dashboard with Recent
Projects and inline Git Status. Projects are inferred from the current working
directory and existing files in Neovim's recent-file list. Press a numbered
shortcut to change to that project and open the file picker; press `q` to quit.
Git status shows the current branch and compact staged, modified, deleted, and
untracked counts, or reports when the current directory is not a Git project.
The dashboard also provides native shortcuts for find files (`f`), grep (`g`),
recent files (`r`), buffers (`b`), tasks (`t`), Git status (`s`), terminal (`T`),
and help (`?`).

## Keymaps

Press `<Space>` and pause briefly to open live keymap hints. Press `<Space>?` to
open fuzzy help. The main navigation actions use the fuzzy picker: files, grep,
buffers, recent files, help, commands, diagnostics, and Git commits. The
dashboard uses the same existing native commands and pickers as the keymaps,
with no additional dashboard dependency.

| Key | Action |
|-----|--------|
| `f` | File: `ff`=find `fg`=grep `fb`=buffers `gc`=commits `fr`=recent |
| `fp` | Copy current file path relative to the project root |
| `c` | Code: `ca`=action `cr`=rename `cf`=format `cs`=symbols |
| `r` | Run: `rr`=task picker `rl`=rerun last `rq`=task quickfix |
| `d` | Debug: `db`=breakpoint `dc`=continue `di`=step in `do`=step over |
| `g` | Git: `gg`=lazygit `gf`=files `gs`=status |
| `p` | Prophet (SFCC): `pe`=enable `pd`=disable `pt`=toggle `pc`=upload all `pf`=find controller `pi`=find template |
| `s` | Search: `sh`=help `sk`=keymaps `sc`=commands `sd`=diagnostics |
| `?` | Fuzzy help |

## Buffer Navigation

Open files appear in a tab bar at the top (like VSCode tabs).

| Key | Action |
|-----|--------|
| `Shift+h` | Previous buffer (tab) |
| `Shift+l` | Next buffer (tab) |
| `<Space>fb` | Show all buffers |
| `<Space>bd` | Close current buffer |
| `<Space>bo` | Close other buffers |

## LSP Navigation

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Go to references |
| `gi` | Go to implementation |
| `gy` | Go to type definition |
| `K` | Hover docs |
| `Ctrl+k` (insert mode) | Signature help |
| `[d` `]d` | Prev/next diagnostic |
| `[e` `]e` | Prev/next error |
| `[h` `]h` | Prev/next git hunk |

## Editing Features

| Key | Action |
|-----|--------|
| `jj` (insert mode) | Exit insert mode |
| `cs"'` | Change surrounding quotes " to ' |
| `ds"` | Delete surrounding quotes |
| `ysiw"` | Surround word with quotes |

## Terminal

| Key | Action |
|-----|--------|
| `Ctrl+/` or `Ctrl+_` | Toggle terminal split (tmux-compatible) |

Open terminal, run `npm run dev`, then `Ctrl+/` (or `Ctrl+_` in tmux) to hide
(keeps running). Press the same shortcut again to show logs.

## Project Tasks

VimZap discovers scripts from the nearest `package.json` and runs them with
Neovim's native asynchronous job API. This gives JavaScript, Next.js, Vitest,
Jest, Playwright, ESLint, and TypeScript projects one consistent task picker.

| Key | Action |
|-----|--------|
| `<Space>rr` | Pick and run an npm script (or `make` when no scripts exist) |
| `<Space>rl` | Rerun the last task |
| `<Space>rq` | Open errors captured from the last task |
| `[q` / `]q` | Previous/next task error |

The task output stays in a reusable split. Lines shaped like
`file:line:column: message` are loaded into quickfix, so `[q` and `]q` jump
directly to failures. The equivalent commands are
`:VimZapTasks`, `:VimZapTask <name>`, `:VimZapTaskLast`, and
`:VimZapTaskQuickfix`.

## Debugging (Node.js)

Start your app with `--inspect`:

```bash
node --inspect server.js
# or for Next.js/Remix:
NODE_OPTIONS='--inspect' npm run dev
```

Then attach in Neovim with `<Space>dc` and select "Attach to Node".

| Key | Action |
|-----|--------|
| `<Space>db` | Toggle breakpoint |
| `<Space>dB` | Conditional breakpoint |
| `<Space>dc` | Continue / Start debugger |
| `<Space>di` | Step into |
| `<Space>do` | Step over |
| `<Space>dO` | Step out |
| `<Space>du` | Toggle debug UI |
| `<Space>de` | Eval expression (works in visual mode) |
| `<Space>dq` | Stop debugger |

## Prophet (Salesforce Commerce Cloud Development)

VimZap includes prophet.nvim for SFCC development with optimized performance and non-intrusive notifications. It aims to match the functionality of the [VSCode Prophet extension](https://github.com/SqrTT/prophet).

### Features

| Feature | VimZap | VSCode Prophet |
|---------|--------|----------------|
| WebDAV Upload | Yes | Yes |
| Auto-upload on save | Yes | Yes |
| ISML Syntax Highlighting | Yes | Yes |
| DWScript (.ds) Support | Yes | Yes |
| Controller Quick-Find | Yes (`<Space>pf`) | Yes (Ctrl+F7) |
| ISML Template Picker | Yes (`<Space>pi`) | Via explorer |
| SFCC Completions | Yes (URLUtils, Resource, server.*) | Yes (full LSP) |
| Snippets | No | Yes |
| Sandbox Connectivity Check | Yes | Yes |
| Full SDAPI Debugger | No (placeholder) | Yes |
| Log Viewer | Browser link | In-editor |

### Setup

**1. Create dw.json in your project root:**
```json
{
  "hostname": "your-sandbox-name.demandware.net",
  "username": "your-username",
  "password": "your-password",
  "code-version": "version1"
}
```

**2. Authentication:**
- **hostname**: Your SFCC sandbox domain (e.g., `dev01-company.demandware.net`)
- **username**: Your Business Manager username
- **password**: Your Business Manager password
- **code-version**: Code version in Business Manager (usually `version1`)

**Important**: Add `dw.json` to your `.gitignore` to avoid committing credentials!

### Usage

| Key | Action |
|-----|--------|
| `<Space>pe` | Enable auto-upload (watches file changes) |
| `<Space>pd` | Disable auto-upload |
| `<Space>pt` | Toggle auto-upload on/off |
| `<Space>pc` | Clean upload all cartridges |
| `<Space>pu` | Upload specific cartridge |
| `<Space>pC` | Check sandbox connectivity |
| `<Space>ps` | Show status |
| `<Space>pf` | Find controller (like Ctrl+F7) |
| `<Space>pi` | Find ISML template |
| `<Space>pl` | View logs (opens browser) |
| `<Space>pr` | Refresh controller cache |

### SFCC Completions

When editing JavaScript files in SFCC projects, you get completions for:
- `URLUtils.url()`, `.http()`, `.https()`, `.abs()`, etc.
- `Resource.msg()`, `Resource.msgf()`
- `server.get()`, `.post()`, `.append()`, `.prepend()`, `.replace()`
- `res.render()`, `.json()`, `.redirect()`, `.setViewData()`
- `Transaction.wrap()`, `.begin()`, `.commit()`, `.rollback()`
- `require('dw/...')` module suggestions

### Tips

- Auto-upload is **disabled by default** to prevent accidental uploads
- Use `<Space>pc` for initial upload of all cartridges
- Enable auto-upload (`<Space>pe`) only when actively developing
- Use `<Space>pf` to quickly jump to any controller endpoint
- All notifications appear in the corner (non-intrusive)

### Cartridge Structure

Prophet.nvim automatically detects cartridges using `.project` files:
```
your-project/
├── dw.json
├── cartridge1/
│   ├── .project
│   └── cartridge/
│       ├── scripts/
│       ├── templates/
│       └── static/
└── cartridge2/
    ├── .project
    └── cartridge/
```

## Clipboard

VimZap uses system clipboard by default:
- `yy` (yank line) → Copies to system clipboard
- `p` → Pastes from system clipboard
- Works with browser Ctrl+C/Ctrl+V

**Tip:** If you delete something after yanking, use `"0p` to paste the yanked text (not the deleted text).

## Update

```bash
bash <(curl -fsSL ifaka.github.io/vimzap/i) update
```

## Plugin Dependencies

Plugins are declared in `lua/plugins.lua`, installed by Neovim's native
`vim.pack`, and recorded in `nvim-pack-lock.json`. Use `:packupdate` to review
and apply plugin updates.

VimZap uses native Neovim wherever it provides the needed capability. The
remaining plugins are deliberately limited to two UX improvements and a few
capability gaps: `mini.pick` provides fuzzy navigation, `which-key.nvim`
provides live leader-key hints, `nvim-lspconfig` supplies server definitions,
`gitsigns.nvim` provides Git signs and hunk actions, `nvim-dap`/`nvim-dap-ui`
provide debugging, and `prophet.nvim` provides SFCC development support.
Diagnostics, completion, formatting through LSP, terminal management, the
dashboard, keymap definitions, and plugin installation use native Neovim APIs
and commands.

The installer automatically installs the JavaScript, HTML/CSS/JSON, Tailwind,
and ESLint language servers used by the SFRA workflow. They are installed
in VimZap's user-local npm prefix (`~/.local/share/vimzap/npm`) and are not
removed by VimZap uninstall because they may be shared by other projects.
TypeScript uses a project-local installation when available and otherwise falls
back to VimZap's managed installation. On macOS,
VimZap prefers the Homebrew Node toolchain even when an older nvm Node is active.

Completion uses Neovim 0.12's native automatic, LSP, buffer, and path sources.
Use `<C-Space>` to request LSP completion, `<Tab>`/`<S-Tab>` to move, and
`<C-y>` to accept a selected item. SFCC candidates use a native completion
source rather than a completion plugin.

`which-key.nvim` provides live hints for leader-key groups. Press `<Space>` and
wait briefly to see available actions; groups include Find, Code, Debug, Git,
Prophet/SFCC, and Search/Help.

## Troubleshooting

### LSP not working

1. Verify LSP is running:
   ```vim
   :checkhealth vim.lsp
   :LspInfo
   ```
2. Make sure the server executable is installed and available on `$PATH`.

### Keymaps not working

1. Verify keymap is loaded:
   ```vim
   :map <Space>
   ```
2. Check for conflicts:
   ```vim
   :verbose map <Space>
   ```

### Missing LSP servers

Run the installer again to repair the standard SFRA tools:
```bash
bash <(curl -fsSL ifaka.github.io/vimzap/i)
```

### Missing external tools

**macOS:**
```bash
brew install lazygit qrencode ripgrep
```

**Linux:**
```bash
sudo apt install lazygit qrencode ripgrep  # Ubuntu/Debian
sudo dnf install lazygit qrencode ripgrep  # Fedora
```

### Markdown share not working

1. Check if qrencode is installed:
   ```bash
   which qrencode
   ```

2. Check if Python 3 is available:
   ```bash
   python3 --version
   ```

3. Install missing dependencies:
   ```bash
   brew install qrencode  # macOS
   sudo apt install qrencode  # Linux
   ```

### Configuration conflicts

If you have existing Neovim config, VimZap will warn before overwriting. To keep both:

1. Backup your config:
   ```bash
   mv ~/.config/nvim ~/.config/nvim.backup
   ```

2. Install VimZap:
   ```bash
   curl -fsSL ifaka.github.io/vimzap/i | bash
   ```

3. Merge configs manually or use VimZap exclusively

## Uninstall

```bash
bash <(curl -fsSL ifaka.github.io/vimzap/i) uninstall
```
