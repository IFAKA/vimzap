-- VimZap: Fast Neovim, LazyVim UX
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

-- Track loaded state
local plugins_loaded = false

-- Load plugins on first buffer
vim.api.nvim_create_autocmd("BufReadPre", {
  once = true,
  callback = function()
    if plugins_loaded then return end
    plugins_loaded = true

    vim.cmd[[packadd gitsigns.nvim]]
    vim.cmd[[packadd nvim-cmp]]
    vim.cmd[[packadd cmp-nvim-lsp]]

    require("gitsigns").setup({
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
    })

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
  end,
})

-- LSP capabilities with completion
local function get_capabilities()
  local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
  if ok then
    return cmp_lsp.default_capabilities()
  end
  return vim.lsp.protocol.make_client_capabilities()
end

-- LSP config (Neovim 0.11+ native API)
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

-- Enable LSP servers
vim.lsp.enable({ "ts_ls", "html", "cssls" })

-- LSP keymaps on attach
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

-- Telescope (lazy-loaded)
local function telescope(cmd)
  vim.cmd[[packadd plenary.nvim]]
  vim.cmd[[packadd telescope.nvim]]
  vim.cmd("Telescope " .. cmd)
end

-- Gitsigns (ensure loaded before commands)
local function gitsigns_cmd(cmd)
  if not plugins_loaded then
    vim.cmd[[packadd gitsigns.nvim]]
    require("gitsigns").setup()
  end
  vim.cmd("Gitsigns " .. cmd)
end

-- Safe LSP commands (check if attached)
local function lsp_cmd(fn)
  return function()
    if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then
      fn()
    else
      vim.notify("No LSP attached", vim.log.levels.WARN)
    end
  end
end

-- Which-key (loaded at startup for instant SPACE popup)
vim.cmd[[packadd which-key.nvim]]
require("which-key").setup({
  delay = 100,
  icons = { mappings = false },
})

require("which-key").add({
  { "<leader>f", group = "file" },
  { "<leader>ff", function() telescope("find_files") end, desc = "find" },
  { "<leader>fg", function() telescope("live_grep") end, desc = "grep" },
  { "<leader>fb", function() telescope("buffers") end, desc = "buffers" },
  { "<leader>fr", function() telescope("oldfiles") end, desc = "recent" },

  { "<leader>c", group = "code" },
  { "<leader>ca", lsp_cmd(vim.lsp.buf.code_action), desc = "action" },
  { "<leader>cr", lsp_cmd(vim.lsp.buf.rename), desc = "rename" },
  { "<leader>cf", lsp_cmd(function() vim.lsp.buf.format() end), desc = "format" },
  { "<leader>cd", vim.diagnostic.open_float, desc = "diagnostic" },

  { "<leader>g", group = "git" },
  { "<leader>gg", ":LazyGit<CR>", desc = "lazygit" },
  { "<leader>gp", function() gitsigns_cmd("preview_hunk") end, desc = "preview" },
  { "<leader>gs", function() gitsigns_cmd("stage_hunk") end, desc = "stage" },
  { "<leader>gr", function() gitsigns_cmd("reset_hunk") end, desc = "reset" },
  { "<leader>gb", function() gitsigns_cmd("blame_line") end, desc = "blame" },

  { "<leader>?", group = "help" },
  { "<leader>??", function()
      vim.cmd[[packadd keyseer.nvim]]
      vim.cmd("KeySeer")
    end, desc = "keys" },

  { "<leader>h", group = "health" },
  { "<leader>hc", ":checkhealth<CR>", desc = "check" },

  { "[d", vim.diagnostic.goto_prev, desc = "prev diagnostic" },
  { "]d", vim.diagnostic.goto_next, desc = "next diagnostic" },
  { "[h", function() gitsigns_cmd("nav_hunk prev") end, desc = "prev hunk" },
  { "]h", function() gitsigns_cmd("nav_hunk next") end, desc = "next hunk" },
})

vim.diagnostic.config({
  virtual_text = true,
  float = { border = "rounded" },
})
