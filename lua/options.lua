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
vim.g.mapleader = " "

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

-- Better completion
vim.opt.completeopt = "menu,menuone,noselect"

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
