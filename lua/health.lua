-- VimZap Health Check
-- Usage: :VimZapHealth

local M = {}

-- Helper to check if command exists
local function command_exists(cmd)
  return vim.fn.executable(cmd) == 1
end

-- Helper to get version from command
local function get_version(cmd, pattern)
  local output = vim.fn.system(cmd)
  if vim.v.shell_error == 0 then
    local version = output:match(pattern)
    return version or "unknown"
  end
  return nil
end

-- Check Neovim version
local function check_neovim_version()
  local version = vim.version()
  local ver_str = string.format("%d.%d.%d", version.major, version.minor, version.patch)
  
  if version.major == 0 and version.minor >= 11 then
    return true, ver_str
  elseif version.major > 0 then
    return true, ver_str
  else
    return false, ver_str
  end
end

-- Check if plugin is loaded
local function check_plugin(name)
  local ok = pcall(require, name)
  return ok
end

-- Check LSP servers installed via Mason
local function check_lsp_servers()
  local mason_path = vim.fn.stdpath("data") .. "/mason/bin"
  local required_servers = {
    { name = "typescript-language-server", cmd = "typescript-language-server" },
    { name = "eslint-lsp", cmd = "vscode-eslint-language-server" },
    { name = "lua-language-server", cmd = "lua-language-server" },
    { name = "html-lsp", cmd = "vscode-html-language-server" },
    { name = "css-lsp", cmd = "vscode-css-language-server" },
    { name = "json-lsp", cmd = "vscode-json-language-server" },
    { name = "tailwindcss-language-server", cmd = "tailwindcss-language-server" },
  }
  
  local results = {}
  for _, server in ipairs(required_servers) do
    local path = mason_path .. "/" .. server.cmd
    results[server.name] = vim.fn.filereadable(path) == 1
  end
  
  return results
end

-- Check external tools
local function check_external_tools()
  return {
    git = command_exists("git"),
    node = command_exists("node"),
    python3 = command_exists("python3"),
    ripgrep = command_exists("rg"),
    lazygit = command_exists("lazygit"),
    qrencode = command_exists("qrencode"),
    prettierd = command_exists("prettierd"),
  }
end

-- Check active LSP clients
local function check_active_lsp()
  local clients = vim.lsp.get_clients()
  local active = {}
  for _, client in ipairs(clients) do
    table.insert(active, client.name)
  end
  return active
end

-- Get startup time
local function get_startup_time()
  local startup_file = vim.fn.tempname()
  vim.fn.system(string.format("nvim --headless --startuptime %s +qa 2>/dev/null", startup_file))
  
  local lines = vim.fn.readfile(startup_file)
  vim.fn.delete(startup_file)
  
  for i = #lines, 1, -1 do
    local line = lines[i]
    if line:match("NVIM STARTED") then
      local time = line:match("^%s*([%d.]+)")
      if time then
        return tonumber(time)
      end
    end
  end
  return nil
end

-- Format the health report
local function format_report()
  local lines = {
    "╭────────────────────────────────────────────────────────╮",
    "│              VimZap Health Check                       │",
    "╰────────────────────────────────────────────────────────╯",
    "",
  }
  
  -- Neovim version
  local nvim_ok, nvim_ver = check_neovim_version()
  table.insert(lines, "┌─ Neovim ──────────────────────────────────────────────")
  if nvim_ok then
    table.insert(lines, string.format("│ ✓ Version: %s (OK)", nvim_ver))
  else
    table.insert(lines, string.format("│ ✗ Version: %s (requires 0.11+)", nvim_ver))
  end
  
  -- Startup time
  table.insert(lines, "│")
  table.insert(lines, "│ Measuring startup time...")
  local startup = get_startup_time()
  if startup then
    if startup < 50 then
      table.insert(lines, string.format("│ ✓ Startup: %.1f ms (excellent)", startup))
    elseif startup < 100 then
      table.insert(lines, string.format("│ ✓ Startup: %.1f ms (good)", startup))
    else
      table.insert(lines, string.format("│ ⚠ Startup: %.1f ms (slow)", startup))
    end
  else
    table.insert(lines, "│ ✗ Could not measure startup time")
  end
  
  table.insert(lines, "")
  
  -- Core plugins
  table.insert(lines, "┌─ Core Plugins ────────────────────────────────────────")
  local core_plugins = {
    { name = "snacks", module = "snacks" },
    { name = "which-key", module = "which-key" },
    { name = "nvim-cmp", module = "cmp" },
    { name = "gitsigns", module = "gitsigns" },
    { name = "mason", module = "mason" },
    { name = "conform", module = "conform" },
    { name = "mini.pairs", module = "mini.pairs" },
    { name = "nvim-treesitter", module = "nvim-treesitter" },
  }
  
  local plugin_ok_count = 0
  for _, plugin in ipairs(core_plugins) do
    local ok = check_plugin(plugin.module)
    if ok then
      table.insert(lines, string.format("│ ✓ %-20s loaded", plugin.name))
      plugin_ok_count = plugin_ok_count + 1
    else
      table.insert(lines, string.format("│ ✗ %-20s missing", plugin.name))
    end
  end
  
  table.insert(lines, "")
  
  -- LSP Servers
  table.insert(lines, "┌─ LSP Servers (Mason) ─────────────────────────────────")
  local lsp_servers = check_lsp_servers()
  local lsp_ok_count = 0
  local lsp_total = 0
  
  for name, installed in pairs(lsp_servers) do
    lsp_total = lsp_total + 1
    if installed then
      table.insert(lines, string.format("│ ✓ %-30s installed", name))
      lsp_ok_count = lsp_ok_count + 1
    else
      table.insert(lines, string.format("│ ✗ %-30s missing", name))
    end
  end
  
  table.insert(lines, "")
  
  -- Active LSP clients
  local active_lsp = check_active_lsp()
  if #active_lsp > 0 then
    table.insert(lines, "┌─ Active LSP Clients ──────────────────────────────────")
    for _, client in ipairs(active_lsp) do
      table.insert(lines, string.format("│ • %s", client))
    end
    table.insert(lines, "")
  end
  
  -- External tools
  table.insert(lines, "┌─ External Tools ──────────────────────────────────────")
  local tools = check_external_tools()
  local tools_ok_count = 0
  local tools_total = 0
  
  local tool_list = {
    { name = "git", required = true },
    { name = "node", required = true },
    { name = "python3", required = true },
    { name = "ripgrep", required = true },
    { name = "lazygit", required = false },
    { name = "qrencode", required = false },
    { name = "prettierd", required = false },
  }
  
  for _, tool in ipairs(tool_list) do
    tools_total = tools_total + 1
    local installed = tools[tool.name]
    if installed then
      table.insert(lines, string.format("│ ✓ %-15s found", tool.name))
      tools_ok_count = tools_ok_count + 1
    else
      if tool.required then
        table.insert(lines, string.format("│ ✗ %-15s missing (required)", tool.name))
      else
        table.insert(lines, string.format("│ ⚠ %-15s missing (optional)", tool.name))
      end
    end
  end
  
  table.insert(lines, "")
  
  -- Summary
  table.insert(lines, "┌─ Summary ─────────────────────────────────────────────")
  table.insert(lines, string.format("│ Neovim:        %s", nvim_ok and "✓" or "✗"))
  table.insert(lines, string.format("│ Plugins:       %d/%d loaded", plugin_ok_count, #core_plugins))
  table.insert(lines, string.format("│ LSP Servers:   %d/%d installed", lsp_ok_count, lsp_total))
  table.insert(lines, string.format("│ Tools:         %d/%d found", tools_ok_count, tools_total))
  
  table.insert(lines, "")
  
  -- Overall status
  local all_ok = nvim_ok and 
                 plugin_ok_count == #core_plugins and 
                 lsp_ok_count == lsp_total and
                 tools.git and tools.node and tools.python3 and tools.ripgrep
  
  if all_ok then
    table.insert(lines, "┌─ Status ──────────────────────────────────────────────")
    table.insert(lines, "│ ✓ VimZap is healthy!")
  else
    table.insert(lines, "┌─ Status ──────────────────────────────────────────────")
    table.insert(lines, "│ ⚠ VimZap has issues (see above)")
    table.insert(lines, "│")
    table.insert(lines, "│ To fix missing LSP servers:")
    table.insert(lines, "│   :Mason")
    table.insert(lines, "│")
    table.insert(lines, "│ To fix missing tools:")
    table.insert(lines, "│   brew install <tool-name>  (macOS)")
    table.insert(lines, "│   apt install <tool-name>   (Linux)")
  end
  
  table.insert(lines, "")
  table.insert(lines, "────────────────────────────────────────────────────────")
  table.insert(lines, string.format("Generated: %s", os.date("%Y-%m-%d %H:%M:%S")))
  table.insert(lines, "")
  
  return table.concat(lines, "\n")
end

-- Run health check
function M.run()
  local notif_id = Snacks.notifier.notify("Running health check...", "info", { timeout = false })
  
  vim.schedule(function()
    local report = format_report()
    
    -- Hide loading notification
    Snacks.notifier.hide(notif_id)
    
    -- Create a floating window for the report
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(report, "\n"))
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
    vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
    
    local width = 60
    local height = #vim.split(report, "\n")
    local win = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = width,
      height = math.min(height, 40),
      row = math.floor((vim.o.lines - height) / 2),
      col = math.floor((vim.o.columns - width) / 2),
      style = "minimal",
      border = "rounded",
      title = " VimZap Health ",
      title_pos = "center",
    })
    
    -- Keymaps for the health window
    vim.keymap.set("n", "q", function()
      vim.api.nvim_win_close(win, true)
    end, { buffer = buf, desc = "Close health check" })
    
    vim.keymap.set("n", "y", function()
      vim.fn.setreg("+", report)
      Snacks.notifier.notify("Health report copied to clipboard!", "info")
    end, { buffer = buf, desc = "Copy health report" })
    
    -- Show keybind hints
    Snacks.notifier.notify("q=close  y=copy to clipboard", "info")
  end)
end

-- Create the command
vim.api.nvim_create_user_command("VimZapHealth", M.run, { desc = "Run VimZap health check" })

return M
