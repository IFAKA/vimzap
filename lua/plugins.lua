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
local dashboard_cmd = [[bash -c '
  fmt() {
    if [ "$1" -ge 1000000 ]; then printf "%.1fM" $(echo "$1/1000000" | bc -l)
    elif [ "$1" -ge 1000 ]; then printf "%.1fk" $(echo "$1/1000" | bc -l)
    else echo "$1"; fi
  }

  echo " $(basename "$PWD")"
  echo "────────────────"

  # Git info or empty state
  if git rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null)
    commit=$(git log -1 --format="%an: %s" 2>/dev/null | cut -c1-40)
    ago=$(git log -1 --format="%cr" 2>/dev/null)
    echo " $branch  $commit  $ago"
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
