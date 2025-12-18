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
| `g` | Git: `gg`=lazygit `gf`=files `gs`=status |
| `s` | Search: `sh`=help `sk`=keymaps `sc`=commands |
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

## Markdown Preview

Open any `.md` file to see rendered headings, code blocks, and tables.

| Command | Action |
|---------|--------|
| `:RenderMarkdown toggle` | Toggle preview on/off |

## Update

```bash
curl -fsSL ifaka.github.io/vimzap/i | bash -s update
```

## Uninstall

```bash
curl -fsSL ifaka.github.io/vimzap/i | bash -s uninstall && source ~/.zshrc
```
