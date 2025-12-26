-- BUTTER-SMOOTH Prophet SFCC operations  
-- Zero lag, fully cancellable uploads

local M = {}

-- State tracking
local state = {
  upload_job = nil,
  is_uploading = false,
}

-- Enhanced notification
local function notify(msg, level)
  level = level or vim.log.levels.INFO
  if pcall(require, "snacks") then
    require("snacks").notifier.notify(msg, {
      title = "🛒 Prophet SFCC",
      level = level,
    })
  else
    vim.notify("[Prophet SFCC] " .. msg, level)
  end
end

-- Check SFCC project
local function check_project()
  local dw_json = vim.fn.findfile("dw.json", ".;")
  if dw_json == "" then
    notify("⚠️ Not in a SFCC project (no dw.json found)", vim.log.levels.WARN)
    return false
  end
  return true
end

-- FORCE CANCEL uploads
function M.force_cancel()
  if state.upload_job then
    vim.fn.jobstop(state.upload_job)
    state.upload_job = nil
  end
  
  -- Kill external processes
  vim.fn.jobstart({"pkill", "-f", "nvim.*prophet"}, {detach = true})
  vim.fn.jobstart({"rm", "-f", "/tmp/prophet_*.lua", "/tmp/prophet_*.log"}, {detach = true})
  
  state.is_uploading = false
  notify("🛑 All uploads cancelled", vim.log.levels.WARN)
end

-- Simple progress monitor using job
function M.clean_upload_async()
  if not check_project() then
    return
  end
  
  if state.is_uploading then
    notify("⚠️ Upload running - use <leader>px to cancel", vim.log.levels.WARN)
    return
  end
  
  state.is_uploading = true
  notify("🚀 Starting async upload (no blocking)...", vim.log.levels.INFO)
  
  -- Create temporary script for external upload
  local script_path = "/tmp/prophet_async_upload.lua"
  local script_content = [[
-- Async Prophet upload
local function log(msg)
  local time = os.date("%H:%M:%S")
  print(string.format("[%s] %s", time, msg))
  io.flush()
end

log("🔧 Loading Prophet...")

local ok = pcall(function()
  vim.cmd('packadd prophet.nvim')
  require('prophet').setup({
    auto_upload = false,
    clean_on_start = false,
    notify = false
  })
end)

if ok then
  log("✅ Prophet loaded")
  
  -- Hook progress
  local utils_ok, utils = pcall(require, 'prophet.utils')
  if utils_ok and utils.show_progress then
    local orig = utils.show_progress
    utils.show_progress = function(current, total, name)
      log(string.format("📊 %d/%d: %s", current, total, name))
    end
  end
  
  log("🚀 Starting upload...")
  local success = pcall(function()
    vim.cmd('ProphetClean')
  end)
  
  if success then
    log("✅ Upload command executed")
    -- Keep alive for 5 minutes max
    vim.defer_fn(function()
      log("📋 Upload completed or timed out")
      vim.cmd('qall!')
    end, 300000)
  else
    log("❌ Upload failed")
    vim.cmd('qall!')
  end
else
  log("❌ Failed to load Prophet")
  vim.cmd('qall!')
end
]]

  -- Write script to file
  local file = io.open(script_path, "w")
  if not file then
    notify("❌ Failed to create script", vim.log.levels.ERROR)
    state.is_uploading = false
    return
  end
  file:write(script_content)
  file:close()
  
  -- Start external process
  state.upload_job = vim.fn.jobstart(
    {"nvim", "--headless", "-S", script_path},
    {
      on_stdout = function(_, data)
        for _, line in ipairs(data) do
          if line and line ~= "" then
            notify("📊 " .. line, vim.log.levels.INFO)
          end
        end
      end,
      on_exit = function(_, code)
        state.is_uploading = false
        state.upload_job = nil
        os.remove(script_path)
        
        if code == 0 then
          notify("✅ Upload completed successfully!", vim.log.levels.INFO)
        else
          notify("⚠️ Upload process ended (check sandbox)", vim.log.levels.WARN)
        end
      end
    }
  )
  
  if state.upload_job <= 0 then
    notify("❌ Failed to start upload job", vim.log.levels.ERROR)
    state.is_uploading = false
    os.remove(script_path)
  end
end





-- Toggle auto-upload
function M.toggle_upload()
  if not pcall(require, "prophet") then
    notify("❌ Prophet not available", vim.log.levels.ERROR)
    return
  end
  
  vim.cmd("ProphetToggle")
  notify("🔄 Auto-upload toggled", vim.log.levels.INFO)
end

-- Show status
function M.show_status()
  if not pcall(require, "prophet") then
    notify("❌ Prophet not available", vim.log.levels.ERROR)
    return
  end
  
  notify("📊 Opening Prophet status...", vim.log.levels.INFO)
  vim.cmd("ProphetStatus")
end

-- Setup all commands and keymaps
function M.setup()
  -- Create user commands - all using optimized async implementation
  vim.api.nvim_create_user_command("ProphetCleanFeedback", M.clean_upload_async, {
    desc = "Async upload with live progress (optimized)"
  })
  
  vim.api.nvim_create_user_command("ProphetCleanExternal", M.clean_upload_async, {
    desc = "Async upload with live progress (optimized)"
  })
  
  vim.api.nvim_create_user_command("ProphetToggleFeedback", M.toggle_upload, {
    desc = "Toggle auto-upload"
  })
  
  vim.api.nvim_create_user_command("ProphetPerFeedback", M.show_status, {
    desc = "Show Prophet status"
  })
  
  vim.api.nvim_create_user_command("ProphetCancel", M.force_cancel, {
    desc = "Force cancel all uploads"
  })
  
  -- Override keymaps if Prophet is available - all using optimized async
  pcall(function()
    if pcall(require, "prophet") then
      vim.keymap.set("n", "<leader>pc", M.clean_upload_async, { desc = "Prophet: Async upload" })
      vim.keymap.set("n", "<leader>pC", M.clean_upload_async, { desc = "Prophet: Async upload" })
      vim.keymap.set("n", "<leader>pt", M.toggle_upload, { desc = "Prophet: Toggle upload" })
      vim.keymap.set("n", "<leader>pp", M.show_status, { desc = "Prophet: Status" })
      vim.keymap.set("n", "<leader>px", M.force_cancel, { desc = "Prophet: Cancel" })
    end
  end)
end

return M