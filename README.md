VimZap

Fast Neovim with file explorer, fuzzy finder, LSP, and git.

Install
```
curl -fsSL ifaka.github.io/vimzap/i | bash
```

Keys (Press SPACE)
```
e        File explorer (toggle)
f        File: ff=find fg=grep fb=buffers fr=recent
c        Code: ca=action cr=rename cf=format cs=symbols
g        Git:  gg=lazygit gf=files gs=status
s        Search: sh=help sk=keymaps sc=commands
?        Show all keymaps
```

Explorer (inside file tree)
```
a        Add file/folder (end with / for folder)
d        Delete
r        Rename
m        Move (select with Tab first)
c        Copy
```

LSP Navigation
```
gd       Go to definition
gr       Go to references
K        Hover docs
[d ]d    Prev/next diagnostic
[h ]h    Prev/next git hunk
```

Update
```
curl -fsSL ifaka.github.io/vimzap/i | bash -s update
```

Uninstall
```
rm -rf ~/.config/nvim ~/.local/share/nvim
```
