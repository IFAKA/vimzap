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

vim.diagnostic.config({
  virtual_text = true,
  float = { border = "rounded" },
})
