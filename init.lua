-- VimZap: Fast Neovim with snacks.nvim
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

-- Load plugins
vim.cmd[[packadd snacks.nvim]]
vim.cmd[[packadd which-key.nvim]]
vim.cmd[[packadd gitsigns.nvim]]
vim.cmd[[packadd nvim-cmp]]
vim.cmd[[packadd cmp-nvim-lsp]]

-- Snacks.nvim setup
require("snacks").setup({
  explorer = { enabled = true, replace_netrw = true },
  picker = { enabled = true },
  notifier = { enabled = true },
  quickfile = { enabled = true },
  input = { enabled = true },
  indent = { enabled = true },
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

-- LSP capabilities
local function get_capabilities()
  local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
  if ok then
    return cmp_lsp.default_capabilities()
  end
  return vim.lsp.protocol.make_client_capabilities()
end

-- LSP config (Neovim 0.11+ native)
vim.lsp.config("ts_ls", {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
  capabilities = get_capabilities(),
})

vim.lsp.config("html", {
  cmd = { "vscode-html-language-server", "--stdio" },
  filetypes = { "html" },
  root_markers = { "package.json", ".git" },
  capabilities = get_capabilities(),
})

vim.lsp.config("cssls", {
  cmd = { "vscode-css-language-server", "--stdio" },
  filetypes = { "css", "scss" },
  root_markers = { "package.json", ".git" },
  capabilities = get_capabilities(),
})

vim.lsp.enable({ "ts_ls", "html", "cssls" })

-- LSP keymaps
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local opts = { buffer = args.buf }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
  end,
})

-- Format on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
  callback = function()
    vim.lsp.buf.format({ async = false, timeout_ms = 3000 })
  end,
})

-- Gitsigns commands helper
local function gitsigns_cmd(cmd)
  vim.cmd("Gitsigns " .. cmd)
end

-- Safe LSP commands
local function lsp_cmd(fn)
  return function()
    if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then
      fn()
    else
      Snacks.notifier.notify("No LSP attached", "warn")
    end
  end
end

-- Which-key
require("which-key").setup({
  delay = 100,
  icons = { mappings = false },
})

require("which-key").add({
  -- Explorer
  { "<leader>e", function() Snacks.explorer() end, desc = "explorer" },

  -- File (using snacks.picker)
  { "<leader>f", group = "file" },
  { "<leader>ff", function() Snacks.picker.files() end, desc = "find" },
  { "<leader>fg", function() Snacks.picker.grep() end, desc = "grep" },
  { "<leader>fb", function() Snacks.picker.buffers() end, desc = "buffers" },
  { "<leader>fr", function() Snacks.picker.recent() end, desc = "recent" },

  -- Code
  { "<leader>c", group = "code" },
  { "<leader>ca", lsp_cmd(vim.lsp.buf.code_action), desc = "action" },
  { "<leader>cr", lsp_cmd(vim.lsp.buf.rename), desc = "rename" },
  { "<leader>cf", lsp_cmd(function() vim.lsp.buf.format() end), desc = "format" },
  { "<leader>cd", vim.diagnostic.open_float, desc = "diagnostic" },
  { "<leader>cs", function() Snacks.picker.lsp_symbols() end, desc = "symbols" },

  -- Git
  { "<leader>g", group = "git" },
  { "<leader>gg", ":LazyGit<CR>", desc = "lazygit" },
  { "<leader>gf", function() Snacks.picker.git_files() end, desc = "git files" },
  { "<leader>gs", function() Snacks.picker.git_status() end, desc = "status" },
  { "<leader>gp", function() gitsigns_cmd("preview_hunk") end, desc = "preview hunk" },
  { "<leader>ga", function() gitsigns_cmd("stage_hunk") end, desc = "stage hunk" },
  { "<leader>gr", function() gitsigns_cmd("reset_hunk") end, desc = "reset hunk" },
  { "<leader>gb", function() gitsigns_cmd("blame_line") end, desc = "blame" },

  -- Search
  { "<leader>s", group = "search" },
  { "<leader>sh", function() Snacks.picker.help() end, desc = "help" },
  { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "keymaps" },
  { "<leader>sc", function() Snacks.picker.commands() end, desc = "commands" },
  { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "diagnostics" },

  -- Help
  { "<leader>?", function() Snacks.picker.keymaps() end, desc = "keymaps" },

  -- Diagnostics navigation
  { "[d", vim.diagnostic.goto_prev, desc = "prev diagnostic" },
  { "]d", vim.diagnostic.goto_next, desc = "next diagnostic" },
  { "[h", function() gitsigns_cmd("nav_hunk prev") end, desc = "prev hunk" },
  { "]h", function() gitsigns_cmd("nav_hunk next") end, desc = "next hunk" },
})

vim.diagnostic.config({
  virtual_text = true,
  float = { border = "rounded" },
})
