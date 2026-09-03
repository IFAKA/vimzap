<img width="1280" height="640" alt="image" src="https://github.com/user-attachments/assets/938952ac-ebfc-40c3-850e-ee798d8339df" />

# VimZap

Fast Neovim with fuzzy finding, LSP, git, formatting, debugging, and SFCC tooling.

**Requirements:** Neovim 0.12+

## Install

```bash
bash <(curl -fsSL ifaka.github.io/vimzap/i)
```

Use `nvim` to open Neovim. `nvim path/to/file:80` opens that file at line 80.

When Neovim starts without a file, VimZap opens a native developer dashboard.
Use `f` to find files, `g` to grep, `r` for recent files, `s` for Git status,
`m` for Mason, `l` for LSP health, `t` for a terminal, `h` for health checks,
and `?` to browse all keymaps.

## Keymaps

Press `<Space>?` to browse all described mappings.

| Key | Action |
|-----|--------|
| `f` | File: `ff`=find `fg`=grep `fb`=buffers `fc`=commits `fr`=recent |
| `fp` | Copy current file path relative to the project root |
| `c` | Code: `ca`=action `cr`=rename `cf`=format `cs`=symbols |
| `d` | Debug: `db`=breakpoint `dc`=continue `di`=step in `do`=step over |
| `g` | Git: `gg`=lazygit `gf`=files `gs`=status |
| `p` | Prophet (SFCC): `pe`=enable `pd`=disable `pt`=toggle `pc`=upload all `pf`=find controller `pi`=find template |
| `s` | Search: `sh`=help `sk`=keymaps `sc`=commands |
| `?` | Show all keymaps |

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
| `gcc` | Comment/uncomment line |
| `gc` (visual) | Comment selection |
| `cs"'` | Change surrounding quotes " to ' |
| `ds"` | Delete surrounding quotes |
| `ysiw"` | Surround word with quotes |

## Terminal

| Key | Action |
|-----|--------|
| `Ctrl+/` | Toggle floating terminal |

Open terminal, run `npm run dev`, then `Ctrl+/` to hide (keeps running). Press `Ctrl+/` again to show logs.

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
and apply plugin updates. Mason remains responsible only for external language
servers, formatters, and the JavaScript debug adapter.

The retained plugins are `mason.nvim`, `nvim-lspconfig`, `mini.nvim` (pick
and comment), `gitsigns.nvim`,
`conform.nvim`, `nvim-dap`, `nvim-dap-ui`, `nvim-nio`, and `prophet.nvim`.
Neovim's native package manager installs them; Mason installs external servers,
formatters, and the JavaScript debug adapter.

Completion uses Neovim 0.12's native automatic, LSP, buffer, and path sources.
Use `<C-Space>` to request LSP completion, `<Tab>`/`<S-Tab>` to move, and
`<C-y>` to accept a selected item. SFCC candidates use a native completion
source rather than a completion plugin.

## Troubleshooting

### LSP not working

1. Check if LSP servers are installed:
   ```vim
   :Mason
   ```
2. Verify LSP is running:
   ```vim
   :LspInfo
   ```
3. Check for errors with `:checkhealth` and inspect `:LspInfo`.

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

LSP servers install automatically on first launch. If they're missing:

```vim
:Mason
```

Then select and install: `i` to install, `X` to uninstall

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
