#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

while IFS= read -r file; do
  if [[ ! -f "$file" ]]; then
    echo "Installer references missing file: $file" >&2
    exit 1
  fi
done < <(awk '/^CONFIG_FILES=\(/,/^\)/ { if ($1 ~ /^"/) { gsub(/"/, "", $1); print $1 } }' i)

reject_match() {
  local pattern=$1
  shift
  if grep -Rq -- "$pattern" "$@"; then
    echo "Unexpected legacy pattern: $pattern" >&2
    exit 1
  fi
}

test ! -e ftdetect/ds.vim
test ! -e ftdetect/isml.vim
test ! -e lua/sfcc.lua
test ! -e lua/benchmark.lua
test ! -e syntax/isml.vim

grep -q 'vim.pack.add' lua/plugins.lua
reject_match 'packadd' lua
reject_match 'which-key\|nvim-cmp\|cmp_nvim_lsp' lua README.md i
reject_match 'snacks\|blink\|oil.nvim\|trouble.nvim\|treesitter\|render-markdown\|ts-autotag' lua README.md i
reject_match 'vim.lsp.start' lua/lsp.lua
grep -q 'requires Neovim 0.12' i
reject_match 'config_updated++\|config_unchanged++' i

nvim --headless -u NONE \
  --cmd "set runtimepath^=$repo_root" \
  --cmd "luafile $repo_root/lua/options.lua" \
  --cmd "luafile $repo_root/lua/keymaps.lua" \
  -c 'lua assert(vim.fn.has("nvim-0.12") == 1)' \
  -c 'lua assert(vim.o.autocomplete == true)' \
  -c 'lua assert(vim.tbl_contains(vim.opt.completeopt:get(), "popup"))' \
  -c 'lua assert(vim.fn.maparg("<Space>w", "n") ~= "")' \
  -c 'lua assert(vim.fn.maparg("<Space>pf", "n"):find("ProphetControllers"))' \
  -c 'lua assert(vim.fn.maparg("<Space>pi", "n"):find("ProphetTemplates"))' \
  -c 'quit!'

echo "VimZap smoke checks passed"
