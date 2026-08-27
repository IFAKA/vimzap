local M = {}
local required = { "git", "node", "rg", "tree-sitter" }
local optional = { "lazygit", "qrencode", "prettierd", "zip", "curl" }
local plugins = { "snacks", "mason", "gitsigns", "conform", "mini.pairs", "nvim-treesitter", "prophet" }

function M.check()
  vim.health.start("VimZap")
  local version = vim.version(); local supported = version.major > 0 or version.minor >= 12
  (supported and vim.health.ok or vim.health.error)(string.format("Neovim %d.%d.%d%s", version.major, version.minor, version.patch, supported and "" or " (0.12+ required)"))
  vim.health.start("Managed plugins")
  for _, module in ipairs(plugins) do local ok = pcall(require, module); (ok and vim.health.ok or vim.health.error)(module) end
  vim.health.start("Required executables")
  for _, cmd in ipairs(required) do (vim.fn.executable(cmd) == 1 and vim.health.ok or vim.health.error)(cmd) end
  vim.health.start("Optional tools")
  for _, cmd in ipairs(optional) do (vim.fn.executable(cmd) == 1 and vim.health.ok or vim.health.warn)(cmd) end
end

function M.run() vim.cmd("checkhealth vimzap vim.pack vim.lsp") end
vim.api.nvim_create_user_command("VimZapHealth", M.run, { desc = "Run VimZap and Neovim health checks" })
return M
