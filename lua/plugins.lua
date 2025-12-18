-- Load plugins
vim.cmd[[packadd mason.nvim]]
vim.cmd[[packadd snacks.nvim]]
vim.cmd[[packadd which-key.nvim]]
vim.cmd[[packadd gitsigns.nvim]]
vim.cmd[[packadd nvim-cmp]]
vim.cmd[[packadd cmp-nvim-lsp]]

-- Mason (LSP server manager)
require("mason").setup()
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

-- Snacks.nvim
require("snacks").setup({
  explorer = { enabled = true, replace_netrw = true },
  picker = { enabled = true },
  notifier = { enabled = true },
  quickfile = { enabled = true },
  input = { enabled = true },
  indent = { enabled = true },
  dashboard = {
    enabled = true,
    preset = {
      header = table.concat({
        "██╗   ██╗██╗███╗   ███╗ ███████╗ █████╗ ██████╗ ",
        "██║   ██║██║████╗ ████║ ╚══███╔╝██╔══██╗██╔══██╗",
        "██║   ██║██║██╔████╔██║   ███╔╝ ███████║██████╔╝",
        "╚██╗ ██╔╝██║██║╚██╔╝██║  ███╔╝  ██╔══██║██╔═══╝ ",
        " ╚████╔╝ ██║██║ ╚═╝ ██║ ███████╗██║  ██║██║     ",
        "  ╚═══╝  ╚═╝╚═╝     ╚═╝ ╚══════╝╚═╝  ╚═╝╚═╝     ",
      }, "\n"),
    },
    sections = {
      { section = "header" },
      { section = "keys", gap = 1, padding = 1 },
      { section = "recent_files", icon = " ", title = "Recent Files", limit = 8, padding = 1 },
      { section = "projects", icon = " ", title = "Projects", limit = 5 },
    },
  },
})

-- Gitsigns
require("gitsigns").setup({
  signs = {
    add = { text = "+" },
    change = { text = "~" },
    delete = { text = "_" },
    topdelete = { text = "‾" },
    changedelete = { text = "~" },
  },
})

-- Completion
local cmp = require("cmp")
cmp.setup({
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = cmp.mapping.select_next_item(),
    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
    ["<C-u>"] = cmp.mapping.scroll_docs(-4),
    ["<C-d>"] = cmp.mapping.scroll_docs(4),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
  }),
})

-- Which-key
require("which-key").setup({
  delay = 100,
  icons = { mappings = false },
})
