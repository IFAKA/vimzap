-- Leader key must be configured before keymaps are registered.
vim.g.mapleader = " "

-- Editor options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.undofile = true
vim.opt.updatetime = 250
-- System clipboard integration
vim.opt.clipboard = "unnamedplus"

-- Better scrolling
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

-- Visual improvements
vim.opt.cursorline = true
vim.opt.wrap = false
vim.opt.linebreak = true

-- Better splits
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Better search
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- Neovim 0.12 native automatic completion. LSP adds its own candidates on
-- attach; the remaining sources cover the current buffer and file paths.
vim.opt.autocomplete = true
vim.opt.complete = ".^5,w^5,b^5,u^5,f^5,o"
vim.opt.completeopt = "menu,menuone,noselect,popup,fuzzy"

-- Project-specific filetypes.
vim.filetype.add({
  extension = {
    ds = "ds",
    isml = "isml",
  },
})

-- Disable swap/backup files
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false

-- Show whitespace characters
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.diagnostic.config({
  virtual_text = true,
  float = { border = "rounded" },
})
