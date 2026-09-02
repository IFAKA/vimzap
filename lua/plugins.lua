local function github(repo)
  return "https://github.com/" .. repo
end

vim.pack.add({
  github("williamboman/mason.nvim"), github("lewis6991/gitsigns.nvim"),
  github("neovim/nvim-lspconfig"),
  github("stevearc/conform.nvim"), github("echasnovski/mini.nvim"),
  github("mfussenegger/nvim-dap"), github("nvim-neotest/nvim-nio"),
  github("rcarriga/nvim-dap-ui"),
  { src = github("IFAKA/prophet.nvim"), version = "v2.*" },
}, { confirm = false })

require("mason").setup()
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH
local registry = require("mason-registry")
local tools = {
  "typescript-language-server", "eslint-lsp", "tailwindcss-language-server",
  "html-lsp", "css-lsp", "json-lsp", "lua-language-server", "pyright", "gopls",
  "clangd", "rust-analyzer", "prettierd", "prettier", "biome", "eslint_d",
  "ruff", "stylua", "rustfmt", "js-debug-adapter",
}
local missing = vim.tbl_filter(function(tool) return not registry.is_installed(tool) end, tools)
if #missing > 0 then
  vim.defer_fn(function() vim.cmd("MasonInstall " .. table.concat(missing, " ")) end, 500)
end

require("gitsigns").setup({
  signs = { add = { text = "+" }, change = { text = "~" }, delete = { text = "_" }, topdelete = { text = "‾" }, changedelete = { text = "~" } },
  current_line_blame = true,
  current_line_blame_opts = { virt_text = true, virt_text_pos = "eol", delay = 500 },
})

require("conform").setup({
  formatters_by_ft = {
    javascript = { "prettierd", "prettier", "biome", "eslint_d", stop_after_first = true },
    javascriptreact = { "prettierd", "prettier", "biome", "eslint_d", stop_after_first = true },
    typescript = { "prettierd", "prettier", "biome", "eslint_d", stop_after_first = true },
    typescriptreact = { "prettierd", "prettier", "biome", "eslint_d", stop_after_first = true },
    json = { "prettierd", "prettier", "biome", stop_after_first = true },
    html = { "prettierd", "prettier", stop_after_first = true },
    css = { "prettierd", "prettier", stop_after_first = true },
    markdown = { "prettierd", "prettier", stop_after_first = true },
    python = { "ruff_format", "ruff_fix", stop_after_first = true },
    lua = { "stylua" }, rust = { "rustfmt" },
  },
})

require("mini.comment").setup()
local clue = require("mini.clue")
clue.setup({
  triggers = {
    { mode = "n", keys = "<Leader>" }, { mode = "x", keys = "<Leader>" },
    { mode = "n", keys = "g" }, { mode = "x", keys = "g" },
    { mode = "n", keys = "[" }, { mode = "n", keys = "]" },
  },
  clues = { clue.gen_clues.g(), clue.gen_clues.builtin_completion(), { mode = "n", keys = "<Leader>", desc = "Leader" } },
  window = { delay = 300, config = { width = "auto" } },
})

require("prophet").setup({
  auto_upload = false, clean_on_start = false, notify = true, dap = { enabled = true },
  picker = function(opts)
    local items = vim.tbl_map(function(item) return { text = item.label, file = item.path, prophet_item = item } end, opts.items)
    require("mini.pick").start({ source = { name = opts.title, items = items, choose = function(item) if item then opts.select(item.prophet_item) end end } })
  end,
})
