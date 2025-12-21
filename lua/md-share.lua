-- Markdown QR Share Plugin
-- Share current markdown file on local network with QR code

local M = {}

-- State
M.server_pid = nil
M.server_url = nil
M.qr_buf = nil
M.qr_win = nil

-- Check if qrencode is installed
local function check_qrencode()
  local result = vim.fn.system("which qrencode")
  return vim.v.shell_error == 0
end

-- Kill the server process
local function kill_server()
  if M.server_pid then
    vim.fn.system("kill " .. M.server_pid)
    M.server_pid = nil
    M.server_url = nil
  end
end

-- Close QR window and kill server
local function close_qr()
  if M.qr_win and vim.api.nvim_win_is_valid(M.qr_win) then
    vim.api.nvim_win_close(M.qr_win, true)
  end
  if M.qr_buf and vim.api.nvim_buf_is_valid(M.qr_buf) then
    vim.api.nvim_buf_delete(M.qr_buf, { force = true })
  end
  M.qr_win = nil
  M.qr_buf = nil
  
  -- Kill server when closing QR
  kill_server()
  
  Snacks.notifier.notify("Server stopped", "info")
end

-- Generate and display QR code
local function show_qr(url)
  -- Generate QR code as UTF-8 art
  local qr_output = vim.fn.system("qrencode -t ANSIUTF8 '" .. url .. "'")
  
  if vim.v.shell_error ~= 0 then
    Snacks.notifier.notify("Failed to generate QR code", "error")
    return
  end
  
  -- Split into lines
  local lines = vim.split(qr_output, "\n", { plain = true })
  
  -- Add header
  table.insert(lines, 1, "")
  table.insert(lines, 2, "  Scan to view on your phone")
  table.insert(lines, 3, "  " .. url)
  table.insert(lines, 4, "")
  table.insert(lines, 5, "  Press q or <Esc> to close")
  table.insert(lines, 6, "")
  
  -- Add footer
  table.insert(lines, "")
  
  -- Create buffer
  M.qr_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(M.qr_buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(M.qr_buf, "modifiable", false)
  vim.api.nvim_buf_set_option(M.qr_buf, "bufhidden", "wipe")
  
  -- Calculate window size
  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  local height = #lines
  
  -- Get editor dimensions
  local ui = vim.api.nvim_list_uis()[1]
  local win_width = ui.width
  local win_height = ui.height
  
  -- Center the window
  local col = math.floor((win_width - width) / 2)
  local row = math.floor((win_height - height) / 2)
  
  -- Create floating window
  M.qr_win = vim.api.nvim_open_win(M.qr_buf, true, {
    relative = "editor",
    width = width + 4,
    height = height + 2,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = " QR Code - Markdown Share ",
    title_pos = "center",
  })
  
  -- Set window options
  vim.api.nvim_win_set_option(M.qr_win, "winblend", 0)
  
  -- Key mappings to close
  local close_keys = { "q", "<Esc>", "<CR>" }
  for _, key in ipairs(close_keys) do
    vim.api.nvim_buf_set_keymap(M.qr_buf, "n", key, "", {
      callback = close_qr,
      noremap = true,
      silent = true,
    })
  end
end

-- Start server and show QR
function M.share()
  -- Check if current buffer is a markdown file
  local filetype = vim.bo.filetype
  if filetype ~= "markdown" then
    Snacks.notifier.notify("Not a markdown file", "warn")
    return
  end
  
  -- Check if qrencode is installed
  if not check_qrencode() then
    Snacks.notifier.notify("Please install qrencode: brew install qrencode", "error")
    return
  end
  
  -- Get current file path
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then
    Snacks.notifier.notify("Save the file first", "warn")
    return
  end
  
  -- Close existing session if any
  if M.server_pid then
    close_qr()
  end
  
  -- Get script path (relative to this lua file)
  local script_path = vim.fn.stdpath("config") .. "/scripts/md-server.py"
  
  -- Create temporary output file for server info
  local tmpfile = vim.fn.tempname()
  
  -- Start server in background and redirect output
  local cmd = string.format("python3 '%s' '%s' > '%s' 2>&1 &", script_path, filepath, tmpfile)
  vim.fn.system(cmd)
  
  -- Wait a bit for server to start and write output
  vim.defer_fn(function()
    local output = vim.fn.readfile(tmpfile)
    vim.fn.delete(tmpfile)
    
    if #output < 2 then
      Snacks.notifier.notify("Failed to start server", "error")
      return
    end
    
    -- Parse output
    local url = nil
    local port = nil
    local note = nil
    local error_msg = nil
    
    for _, line in ipairs(output) do
      local u = line:match("URL:(.+)")
      if u then url = vim.trim(u) end
      
      local p = line:match("PORT:(.+)")
      if p then port = vim.trim(p) end
      
      local n = line:match("NOTE:(.+)")
      if n then note = vim.trim(n) end
      
      local e = line:match("ERROR:(.+)")
      if e then error_msg = vim.trim(e) end
    end
    
    if error_msg then
      Snacks.notifier.notify(error_msg, "error")
      return
    end
    
    if not url or not port then
      Snacks.notifier.notify("Failed to parse server output", "error")
      return
    end
    
    M.server_url = url
    
    -- Get server PID
    local pid_output = vim.fn.system("lsof -ti:" .. port)
    if vim.v.shell_error == 0 and pid_output ~= "" then
      M.server_pid = tonumber(vim.trim(pid_output))
    end
    
    -- Show QR code
    show_qr(url)
    
    -- Show notification with port info
    if note then
      Snacks.notifier.notify(note, "info")
    else
      Snacks.notifier.notify("Server running on port " .. port, "info")
    end
  end, 1000)
end

return M
