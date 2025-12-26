-- VimZap: Fast Neovim with snacks.nvim
-- Add current directory to runtime path for standalone mode
vim.opt.runtimepath:prepend(vim.fn.getcwd())
require("options")
require("plugins")
require("lsp")
require("debug")
require("keymaps")
require("benchmark")
require("health")

-- Load custom user configuration (optional)
-- Create ~/.config/nvim/vimzap-custom.lua to override settings
local custom_config = vim.fn.stdpath("config") .. "/vimzap-custom.lua"
if vim.fn.filereadable(custom_config) == 1 then
  dofile(custom_config)
end

-- Load Prophet feedback features (if available) - load last to ensure all deps are ready
local prophet_ok, prophet_feedback = pcall(require, "prophet-feedback")
if prophet_ok then
  prophet_feedback.setup()
end