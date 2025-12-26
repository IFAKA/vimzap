-- Load plugins
vim.cmd[[packadd mason.nvim]]
vim.cmd[[packadd snacks.nvim]]
vim.cmd[[packadd which-key.nvim]]
vim.cmd[[packadd gitsigns.nvim]]
vim.cmd[[packadd nvim-cmp]]
vim.cmd[[packadd cmp-nvim-lsp]]
vim.cmd[[packadd cmp-buffer]]
vim.cmd[[packadd cmp-path]]
vim.cmd[[packadd render-markdown.nvim]]
vim.cmd[[packadd conform.nvim]]
vim.cmd[[packadd mini.nvim]]
vim.cmd[[packadd nvim-treesitter]]
pcall(vim.cmd, [[packadd prophet.nvim]])

-- Mason (LSP server manager)
require("mason").setup()
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

-- Auto-install tools via Mason
local mason_registry = require("mason-registry")
local ensure_installed = {
  "typescript-language-server",
  "eslint-lsp",
  "tailwindcss-language-server",
  "html-lsp",
  "css-lsp",
  "json-lsp",
  "lua-language-server",
  "prettierd",
  "stylua",
  "js-debug-adapter",
}
local to_install = {}
for _, tool in ipairs(ensure_installed) do
  if not mason_registry.is_installed(tool) then
    table.insert(to_install, tool)
  end
end
if #to_install > 0 then
  vim.defer_fn(function()
    vim.cmd("MasonInstall " .. table.concat(to_install, " "))
  end, 500)
end

-- Snacks.nvim
local dashboard_cmd = [[bash -c '
  fmt() {
    if [ "$1" -ge 1000000 ]; then printf "%.1fM" $(echo "$1/1000000" | bc -l)
    elif [ "$1" -ge 1000 ]; then printf "%.1fk" $(echo "$1/1000" | bc -l)
    else echo "$1"; fi
  }

  short_time() {
    echo "$1" | sed -E "s/ seconds?/ s/; s/ minutes?/ m/; s/ hours?/ h/; s/ days?/ d/; s/ weeks?/ w/; s/ months?/ mo/; s/ years?/ y/; s/ ago//"
  }

  echo " $(basename "$PWD")"
  echo "────────────────"

  # Git info or empty state
  if git rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null)
    commit=$(git log -1 --format="%an: %s" 2>/dev/null | cut -c1-40)
    ago=$(short_time "$(git log -1 --format="%cr" 2>/dev/null)")
    echo " $branch  $commit | $ago"
    changes=$(git status --porcelain 2>/dev/null | wc -l | tr -d " ")
    files=$(git ls-files "*.lua" "*.ts" "*.tsx" "*.js" "*.py" 2>/dev/null | wc -l | tr -d " ")
  else
    echo " not a git repo"
    changes=0
    ignore="node_modules|dist|build|.next|.nuxt|coverage|.cache|vendor|__pycache__|.venv|venv|.git"
    files=$(find . -type f \( -name "*.lua" -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.py" \) 2>/dev/null | grep -Ev "$ignore" | wc -l | tr -d " ")
  fi

  echo "$(fmt $changes) changes | $(fmt $files) files"
']]

require("snacks").setup({
  explorer = { enabled = true, replace_netrw = true },
  picker = { enabled = true },
  notifier = { enabled = true },
  quickfile = { enabled = true },
  input = { enabled = true },
  indent = { enabled = true },
  words = { enabled = true }, -- Auto-highlight references under cursor
  terminal = { enabled = true }, -- Floating terminal
  bufdelete = { enabled = true }, -- Smart buffer deletion
  dashboard = {
    enabled = true,
    sections = {
      { section = "terminal", cmd = dashboard_cmd, height = 4, padding = 1 },
      { section = "keys", gap = 1, padding = 1 },
      { section = "recent_files", icon = " ", title = "Recent Files", limit = 8, padding = 1 },
      { section = "projects", icon = " ", title = "Projects", limit = 5 },
    },
  },
})

-- Simple bufferline (shows open buffers like VSCode tabs)
vim.opt.showtabline = 2 -- Always show
function _G.custom_tabline()
  local s = ''
  for i = 1, vim.fn.bufnr('$') do
    if vim.fn.buflisted(i) == 1 then
      local name = vim.fn.bufname(i)
      name = name ~= '' and vim.fn.fnamemodify(name, ':t') or '[No Name]'
      if i == vim.fn.bufnr('%') then
        s = s .. '%#TabLineSel# ' .. name .. ' %#TabLineFill#'
      else
        s = s .. '%#TabLine# ' .. name .. ' '
      end
    end
  end
  return s
end
vim.opt.tabline = "%!v:lua.custom_tabline()"

-- Gitsigns
require("gitsigns").setup({
  signs = {
    add = { text = "+" },
    change = { text = "~" },
    delete = { text = "_" },
    topdelete = { text = "‾" },
    changedelete = { text = "~" },
  },
  current_line_blame = true,
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
    delay = 500,
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
    { name = "nvim_lsp", priority = 1000 },
    { name = "buffer", priority = 500 },
    { name = "path", priority = 250 },
  }),
})

-- Which-key
require("which-key").setup({
  delay = 100,
  icons = { mappings = false },
})

-- Render Markdown (in-editor markdown preview)
require("render-markdown").setup({
  file_types = { "markdown" },
  render_modes = { "n", "c" }, -- Normal and command mode
})

-- Conform (formatter)
require("conform").setup({
  formatters_by_ft = {
    javascript = { "prettierd", "prettier", stop_after_first = true },
    javascriptreact = { "prettierd", "prettier", stop_after_first = true },
    typescript = { "prettierd", "prettier", stop_after_first = true },
    typescriptreact = { "prettierd", "prettier", stop_after_first = true },
    json = { "prettierd", "prettier", stop_after_first = true },
    html = { "prettierd", "prettier", stop_after_first = true },
    css = { "prettierd", "prettier", stop_after_first = true },
    markdown = { "prettierd", "prettier", stop_after_first = true },
    lua = { "stylua" },
  },
})

-- Mini.nvim plugins
require("mini.pairs").setup() -- Auto-pairs for brackets/quotes
require("mini.comment").setup() -- Comment toggling with gcc
require("mini.surround").setup() -- Surround operations (cs"', ysiw", etc.)

-- Treesitter (better syntax highlighting)
-- Auto-install common language parsers
vim.defer_fn(function()
  local parsers = { "lua", "javascript", "typescript", "tsx", "html", "css", "json", "markdown", "markdown_inline", "vim", "vimdoc" }
  local success, ts = pcall(require, "nvim-treesitter")
  if success then
    local ok = pcall(function()
      ts.install(parsers)
    end)
    if not ok then
      vim.notify("Treesitter: Some parsers may not have installed. They will auto-install when opening files.", vim.log.levels.WARN)
    end
  else
    vim.notify("Treesitter not found. Syntax highlighting may be limited.", vim.log.levels.WARN)
  end
end, 1000)

-- Prophet (SFCC Development)
-- Silently setup - only activates when dw.json is found
pcall(function()
  require("prophet").setup({
    auto_upload = false,    -- Don't watch by default
    clean_on_start = true,  -- Upload all on startup
    notify = true,          -- Show notifications
  })
end)
