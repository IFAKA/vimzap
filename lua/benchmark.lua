-- VimZap Performance Benchmark
-- Usage: :VimZapBench or <leader>B

local M = {}

-- Get system info
local function get_system_info()
  local uname = vim.fn.system("uname -srm"):gsub("\n", "")
  local cpu = vim.fn.system("sysctl -n machdep.cpu.brand_string 2>/dev/null || cat /proc/cpuinfo 2>/dev/null | grep 'model name' | head -1 | cut -d: -f2"):gsub("^%s+", ""):gsub("\n", "")
  local ram = vim.fn.system("sysctl -n hw.memsize 2>/dev/null || grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2*1024}'"):gsub("\n", "")
  local ram_gb = tonumber(ram) and string.format("%.0f GB", tonumber(ram) / 1024 / 1024 / 1024) or "Unknown"
  local hostname = vim.fn.hostname()

  return {
    os = uname,
    cpu = cpu ~= "" and cpu or "Unknown",
    ram = ram_gb,
    hostname = hostname,
    nvim_version = vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
  }
end

-- Measure startup time
local function measure_startup()
  local startup_file = vim.fn.tempname()
  local cmd = string.format(
    "nvim --startuptime %s -c 'qall' 2>/dev/null && tail -1 %s | awk '{print $1}'",
    startup_file, startup_file
  )
  local result = vim.fn.system(cmd):gsub("\n", "")
  vim.fn.delete(startup_file)
  return tonumber(result) or 0
end

-- Measure startup with a file
local function measure_startup_with_file(filetype)
  local startup_file = vim.fn.tempname()
  local test_file = vim.fn.tempname() .. "." .. filetype
  vim.fn.writefile({""}, test_file)
  local cmd = string.format(
    "nvim --startuptime %s %s -c 'qall' 2>/dev/null && tail -1 %s | awk '{print $1}'",
    startup_file, test_file, startup_file
  )
  local result = vim.fn.system(cmd):gsub("\n", "")
  vim.fn.delete(startup_file)
  vim.fn.delete(test_file)
  return tonumber(result) or 0
end

-- Get plugin count
local function get_plugin_count()
  local plugin_dir = vim.fn.stdpath("data") .. "/site/pack/plugins/opt"
  local plugins = vim.fn.globpath(plugin_dir, "*", 0, 1)
  return #plugins
end

-- Get disk usage
local function get_disk_usage()
  local config_size = vim.fn.system("du -sh ~/.config/nvim 2>/dev/null | awk '{print $1}'"):gsub("\n", "")
  local data_size = vim.fn.system("du -sh ~/.local/share/nvim 2>/dev/null | awk '{print $1}'"):gsub("\n", "")
  return {
    config = config_size ~= "" and config_size or "N/A",
    data = data_size ~= "" and data_size or "N/A",
  }
end

-- Get active LSP servers
local function get_lsp_info()
  local servers = {}
  for name, _ in pairs(vim.lsp._configs or {}) do
    table.insert(servers, name)
  end
  table.sort(servers)
  return servers
end

-- Get loaded plugins with timing
local function get_plugin_timing()
  local startup_file = vim.fn.tempname()
  vim.fn.system(string.format("nvim --startuptime %s -c 'qall' 2>/dev/null", startup_file))

  local plugins = {}
  local lines = vim.fn.readfile(startup_file)
  for _, line in ipairs(lines) do
    local time, _, plugin = line:match("^%s*([%d.]+)%s+[%d.]+%s+[%d.]+:%s+sourcing%s+.*/pack/plugins/opt/([^/]+)/")
    if time and plugin then
      plugins[plugin] = (plugins[plugin] or 0) + tonumber(time)
    end
  end
  vim.fn.delete(startup_file)

  local result = {}
  for name, time in pairs(plugins) do
    table.insert(result, { name = name, time = time })
  end
  table.sort(result, function(a, b) return a.time > b.time end)
  return result
end

-- Format the benchmark report
local function format_report(data)
  local lines = {
    "╭────────────────────────────────────────────────────────╮",
    "│              VimZap Performance Benchmark              │",
    "╰────────────────────────────────────────────────────────╯",
    "",
    "┌─ System ─────────────────────────────────────────────────",
    string.format("│ Host:    %s", data.system.hostname),
    string.format("│ OS:      %s", data.system.os),
    string.format("│ CPU:     %s", data.system.cpu),
    string.format("│ RAM:     %s", data.system.ram),
    string.format("│ Neovim:  %s", data.system.nvim_version),
    "",
    "┌─ Startup Time ───────────────────────────────────────────",
    string.format("│ Empty buffer:  %6.1f ms", data.startup.empty),
    string.format("│ TSX file:      %6.1f ms", data.startup.tsx),
    string.format("│ Lua file:      %6.1f ms", data.startup.lua),
    "",
    "┌─ Plugins (" .. data.plugin_count .. " total) ─────────────────────────────────────",
  }

  for i, plugin in ipairs(data.plugins) do
    if i <= 8 then
      table.insert(lines, string.format("│ %-25s %6.1f ms", plugin.name, plugin.time))
    end
  end

  table.insert(lines, "")
  table.insert(lines, "┌─ Disk Usage ──────────────────────────────────────────────")
  table.insert(lines, string.format("│ Config (~/.config/nvim):     %s", data.disk.config))
  table.insert(lines, string.format("│ Data (~/.local/share/nvim):  %s", data.disk.data))

  table.insert(lines, "")
  table.insert(lines, "┌─ LSP Servers ─────────────────────────────────────────────")
  if #data.lsp > 0 then
    table.insert(lines, "│ " .. table.concat(data.lsp, ", "))
  else
    table.insert(lines, "│ (none configured)")
  end

  table.insert(lines, "")
  table.insert(lines, "────────────────────────────────────────────────────────────")
  table.insert(lines, string.format("Generated: %s", os.date("%Y-%m-%d %H:%M:%S")))
  table.insert(lines, "")

  return table.concat(lines, "\n")
end

-- Format shareable one-liner
local function format_shareable(data)
  return string.format(
    "VimZap: %dms startup | %d plugins | %s disk | %s | %s RAM | nvim %s",
    math.floor(data.startup.empty),
    data.plugin_count,
    data.disk.data,
    data.system.cpu:match("^[^@]+"):gsub("%s+$", ""),
    data.system.ram,
    data.system.nvim_version
  )
end

-- Run the benchmark
function M.run()
  -- Show loading notification
  local notif_id = Snacks.notifier.notify("Running benchmark...", "info", { timeout = false })

  vim.schedule(function()
    local data = {
      system = get_system_info(),
      startup = {
        empty = measure_startup(),
        tsx = measure_startup_with_file("tsx"),
        lua = measure_startup_with_file("lua"),
      },
      plugin_count = get_plugin_count(),
      plugins = get_plugin_timing(),
      disk = get_disk_usage(),
      lsp = get_lsp_info(),
    }

    -- Hide loading notification
    Snacks.notifier.hide(notif_id)

    local report = format_report(data)
    local shareable = format_shareable(data)

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
      height = math.min(height, 30),
      row = math.floor((vim.o.lines - height) / 2),
      col = math.floor((vim.o.columns - width) / 2),
      style = "minimal",
      border = "rounded",
      title = " VimZap Benchmark ",
      title_pos = "center",
    })

    -- Keymaps for the benchmark window
    vim.keymap.set("n", "q", function()
      vim.api.nvim_win_close(win, true)
    end, { buffer = buf, desc = "Close benchmark" })

    vim.keymap.set("n", "y", function()
      vim.fn.setreg("+", report)
      Snacks.notifier.notify("Full report copied to clipboard!", "info")
    end, { buffer = buf, desc = "Copy full report" })

    vim.keymap.set("n", "s", function()
      vim.fn.setreg("+", shareable)
      Snacks.notifier.notify("Shareable summary copied!", "info")
    end, { buffer = buf, desc = "Copy shareable summary" })

    -- Show keybind hints
    Snacks.notifier.notify("q=close  y=copy report  s=copy shareable", "info")
  end)
end

-- Create the command
vim.api.nvim_create_user_command("VimZapBench", M.run, { desc = "Run VimZap performance benchmark" })

return M
