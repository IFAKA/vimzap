VimZap

Fast Neovim setup with LSP, completion, and fuzzy finding.

Install
```
curl -fsSL ifaka.github.io/vimzap/i | bash
```

Keys (Press SPACE)
```
f   file: ff=find fg=grep fb=buffers fr=recent
c   code: ca=action cr=rename cf=format cd=diagnostic
g   git:  gg=lazygit gp=preview gs=stage gr=reset gb=blame
?   help: ??=key visualizer
h   health: hc=checkhealth
```

Navigation
```
gd          Go to definition
gr          Go to references
K           Hover documentation
[d / ]d     Prev/next diagnostic
[h / ]h     Prev/next git hunk
```

Uninstall
```
rm -rf ~/.config/nvim ~/.local/share/nvim
```
