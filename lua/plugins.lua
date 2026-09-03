-- Keep only plugins for features Neovim does not provide itself.
vim.pack.add({
  "https://github.com/echasnovski/mini.nvim",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/mfussenegger/nvim-dap",
  "https://github.com/nvim-neotest/nvim-nio",
  "https://github.com/rcarriga/nvim-dap-ui",
  { src = "https://github.com/IFAKA/prophet.nvim", version = "v2.*" },
}, { confirm = false, load = true })

require("mini.pick").setup()
require("gitsigns").setup({
  signs = { add = { text = "+" }, change = { text = "~" }, delete = { text = "_" }, topdelete = { text = "‾" }, changedelete = { text = "~" } },
  current_line_blame = true,
  current_line_blame_opts = { virt_text = true, virt_text_pos = "eol", delay = 500 },
})

require("prophet").setup({
  auto_upload = false, clean_on_start = false, notify = true, dap = { enabled = true },
})
