<img width="1280" height="640" alt="image" src="https://github.com/user-attachments/assets/938952ac-ebfc-40c3-850e-ee798d8339df" />

# VimZap

Fast Neovim with file explorer, fuzzy finder, LSP, git, and markdown preview.

**Requirements:** Neovim 0.11+

## Install

```bash
bash <(curl -fsSL ifaka.github.io/vimzap/i)
```

Then use `v`, `vi`, or `vim` to open Neovim.

## Keymaps

Press `<Space>` to open the command menu.

| Key | Action |
|-----|--------|
| `e` | File explorer (toggle) |
| `f` | File: `ff`=find `fg`=grep `fb`=buffers `fr`=recent |
| `c` | Code: `ca`=action `cr`=rename `cf`=format `cs`=symbols |
| `d` | Debug: `db`=breakpoint `dc`=continue `di`=step in `do`=step over |
| `g` | Git: `gg`=lazygit `gf`=files `gs`=status |
| `p` | Prophet (SFCC): `pe`=enable `pd`=disable `pt`=toggle `pc`=upload all `pf`=find controller `pi`=find template |
| `s` | Search: `sh`=help `sk`=keymaps `sc`=commands `sq`=share markdown (QR) |
| `h` | Health check (diagnostics + performance) |
| `?` | Show all keymaps |

## Explorer

Inside the file tree:

| Key | Action |
|-----|--------|
| `a` | Add file/folder (end with `/` for folder) |
| `d` | Delete |
| `r` | Rename |
| `m` | Move (select with Tab first) |
| `c` | Copy |

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
| Snippets | Yes | Yes |
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

## Markdown Preview

Open any `.md` file to see rendered headings, code blocks, and tables.

| Command | Action |
|---------|--------|
| `:RenderMarkdown toggle` | Toggle preview on/off |

## Markdown Sharing (QR Code)

Share your markdown file to your phone for reading on the go.

**Setup:**
```bash
brew install qrencode
```

**Usage:**

1. Open a markdown file in Neovim
2. Press `<Space>sq` to show QR code
3. Scan with your phone to open rendered markdown in browser
4. Press `q` or `<Esc>` to close QR and stop server

The server runs only on your local network and stops automatically when you close the QR window.

## Update

```bash
bash <(curl -fsSL ifaka.github.io/vimzap/i) update
```

## Health Check

Run diagnostics to verify your setup:

```vim
:VimZapHealth
```

Or use the keymap: `<Space>h`

This checks:
- Neovim version
- Plugin installation
- LSP servers
- External tools
- Startup performance

## Plugin Dependencies

VimZap includes both **required** and **optional** plugins:

### Required Plugins (automatically installed)
- `snacks.nvim` - Dashboard, file explorer, fuzzy finder
- `mason.nvim` - LSP server manager  
- `nvim-cmp` + completion sources - Autocompletion
- `which-key.nvim` - Keymap hints
- `gitsigns.nvim` - Git integration
- `render-markdown.nvim` - Markdown preview
- `conform.nvim` - Code formatting
- `mini.nvim` - Pairs, comments, surround
- `nvim-treesitter` - Syntax highlighting

### Optional Plugins (safe to skip)
- `nvim-ts-autotag` - Auto-close HTML/JSX tags
- `nvim-dap` + `nvim-dap-ui` + `nvim-nio` - Debug support
- `prophet.nvim` - Salesforce Commerce Cloud development

**Note:** VimZap will continue to work even if optional plugins are missing. You may see reduced functionality for specific features (like debugging or SFCC development) but core editing will work fine.

To install optional plugins, use your preferred Neovim package manager or add them to your `packpath`.

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
3. Check for errors:
   ```vim
   :VimZapHealth
   ```

### Slow startup

1. Run benchmark:
   ```vim
   :VimZapBench
   ```
   Or press `<Space>B`

2. If startup > 100ms, check plugin load times in the benchmark output

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
