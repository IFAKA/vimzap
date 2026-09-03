vim.pack.add({
  "https://github.com/williamboman/mason.nvim",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/stevearc/conform.nvim",
  "https://github.com/echasnovski/mini.nvim",
  "https://github.com/mfussenegger/nvim-dap",
  "https://github.com/nvim-neotest/nvim-nio",
  "https://github.com/rcarriga/nvim-dap-ui",
  { src = "https://github.com/IFAKA/prophet.nvim", version = "v2.*" },
}, { confirm = false })

require("mason").setup()
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH
vim.defer_fn(function()
  local registry = require("mason-registry")
  local tools = {
    "typescript-language-server", "eslint-lsp", "tailwindcss-language-server",
    "html-lsp", "css-lsp", "json-lsp", "lua-language-server", "pyright", "gopls",
    "clangd", "rust-analyzer", "prettierd", "prettier", "biome", "eslint_d",
    "ruff", "stylua", "rustfmt", "js-debug-adapter",
  }
  local missing = vim.tbl_filter(function(tool) return not registry.is_installed(tool) end, tools)
  if #missing > 0 then
    vim.cmd("MasonInstall " .. table.concat(missing, " "))
  end
end, 1000)

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

require("prophet").setup({
  auto_upload = false, clean_on_start = false, notify = true, dap = { enabled = true },
  picker = function(opts)
    local items = vim.tbl_map(function(item) return { text = item.label, file = item.path, prophet_item = item } end, opts.items)
    require("mini.pick").start({ source = { name = opts.title, items = items, choose = function(item) if item then opts.select(item.prophet_item) end end } })
  end,
})
