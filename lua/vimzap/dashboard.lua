-- Native startup dashboard. It only appears when Nvim starts without a file.

local function picker(method)
  return function() require("mini.pick").builtin[method]() end
end

local function open_dashboard()
  if vim.fn.argc() ~= 0 or vim.api.nvim_buf_get_name(0) ~= "" or vim.bo.buftype ~= "" then return end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "", "  VimZap", "", "  Developer dashboard", "",
    "  f  Find files        g  Grep project       r  Recent files",
    "  s  Git status        m  Mason tools        l  LSP health",
    "  t  Terminal           h  Neovim health      ?  All keymaps",
    "  q  Quit", "", "  Open a file to start coding.",
  })
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = "vimzap-dashboard"
  vim.bo[buf].modifiable = false
  vim.bo[buf].buflisted = false
  vim.bo[buf].swapfile = false
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = "no"
  vim.wo.cursorline = false

  local function map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = buf, silent = true, desc = desc })
  end

  map("f", picker("files"), "Find files")
  map("g", picker("grep_live"), "Grep project")
  map("r", picker("oldfiles"), "Recent files")
  map("s", picker("git_status"), "Git status")
  map("m", "<cmd>Mason<cr>", "Manage external tools")
  map("l", "<cmd>checkhealth vim.lsp<cr>", "LSP health")
  map("t", "<cmd>botright split | terminal<cr>", "Open terminal")
  map("h", "<cmd>checkhealth<cr>", "Neovim health")
  map("?", picker("keymaps"), "Show all keymaps")
  map("q", "<cmd>quit<cr>", "Quit")
  map("<CR>", picker("files"), "Find files")
end

vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = open_dashboard })
