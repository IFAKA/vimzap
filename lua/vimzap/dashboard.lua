-- Small native startup dashboard. It only appears when Nvim starts without a file.
local function open_dashboard()
  if vim.fn.argc() ~= 0 or vim.api.nvim_buf_get_name(0) ~= "" or vim.bo.buftype ~= "" then return end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "", "  VimZap", "", "  Native developer dashboard", "",
    "  <Space>ff  Find files       <Space>fg  Grep project",
    "  <Space>fr  Recent files      <Space>gs  Git status",
    "  <Space>cf  Format with LSP    <Space>rr  Run project task",
    "  <Space>?   Show keymaps",
    "  <C-_>      Terminal           q         Quit", "",
    "  Open a file to start coding.",
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
  map("f", "<cmd>VimZapFiles<cr>", "Find files")
  map("g", "<cmd>VimZapGrep<cr>", "Grep project")
  map("r", "<cmd>VimZapRecent<cr>", "Recent files")
  map("R", "<cmd>VimZapTasks<cr>", "Run project task")
  map("s", "<leader>gs", "Git status")
  map("t", "<cmd>VimZapTerminalToggle<cr>", "Toggle terminal")
  map("<leader>?", "<cmd>map<cr>", "Show keymaps")
  map("q", "<cmd>quit<cr>", "Quit")
  map("<CR>", "<cmd>VimZapFiles<cr>", "Find files")
end

vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = open_dashboard })
