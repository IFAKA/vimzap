#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

test ! -e ftdetect/ds.vim
test ! -e ftdetect/isml.vim

grep -q 'vim.pack.add' lua/plugins.lua
! grep -Rq 'packadd' lua
! grep -Rq 'which-key\|nvim-cmp\|cmp_nvim_lsp' lua README.md i
! grep -q 'vim.lsp.start' lua/lsp.lua
grep -q 'requires Neovim 0.12' i

nvim --headless -u NONE \
  --cmd "set runtimepath^=$repo_root" \
  --cmd "luafile $repo_root/lua/options.lua" \
  --cmd "luafile $repo_root/lua/sfcc.lua" \
  --cmd "luafile $repo_root/lua/keymaps.lua" \
  -c 'lua assert(vim.fn.has("nvim-0.12") == 1)' \
  -c 'lua assert(vim.o.autocomplete == true)' \
  -c 'lua assert(vim.tbl_contains(vim.opt.completeopt:get(), "popup"))' \
  -c 'lua assert(vim.fn.maparg("<Space>w", "n") ~= "")' \
  -c 'lua assert(vim.fn.maparg("<Tab>", "i", false, true).expr == 1)' \
  -c 'lua assert(vim.filetype.match({ filename = "example.isml" }) == "isml")' \
  -c 'lua assert(vim.filetype.match({ filename = "example.ds" }) == "ds")' \
  -c 'lua vim.o.virtualedit = "onemore"; vim.api.nvim_set_current_line("URLUtils."); vim.api.nvim_win_set_cursor(0, { 1, 9 }); assert(require("sfcc").completefunc(0, "")[1].word == "url")' \
  -c 'quit!'

echo "VimZap smoke checks passed"
