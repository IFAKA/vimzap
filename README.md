<img width="1280" height="640" alt="image" src="https://github.com/user-attachments/assets/938952ac-ebfc-40c3-850e-ee798d8339df" />

# VimZap

Fast Neovim with file explorer, fuzzy finder, LSP, git, and markdown preview.

## Install

```bash
curl -fsSL ifaka.github.io/vimzap/i | bash && source ~/.zshrc
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
| `s` | Search: `sh`=help `sk`=keymaps `sc`=commands `sq`=share markdown (QR) |
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

## LSP Navigation

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Go to references |
| `K` | Hover docs |
| `[d` `]d` | Prev/next diagnostic |
| `[h` `]h` | Prev/next git hunk |

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
curl -fsSL ifaka.github.io/vimzap/i | bash -s update
```

## Uninstall

```bash
curl -fsSL ifaka.github.io/vimzap/i | bash -s uninstall && source ~/.zshrc
```
