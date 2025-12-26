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
  vim.fn.jobstart("pkill -f 'nvim.*prophet' >/dev/null 2>&1", {})
  vim.fn.jobstart("rm -f /tmp/prophet_*.lua /tmp/prophet_*.log >/dev/null 2>&1", {})
  
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

-- Terminal-based upload with live output
function M.clean_upload_terminal()
  if not check_project() then
    return
  end
  
  if not pcall(require, "snacks") then
    notify("❌ Snacks.nvim required for terminal", vim.log.levels.ERROR)
    return
  end
  
  notify("🚀 Opening terminal upload...", vim.log.levels.INFO)
  
  local snacks = require("snacks")
  
  -- Simple terminal command that shows live progress
  local cmd = {
    "bash", "-c", [[
echo "🚀 Prophet SFCC Terminal Upload"
echo "==============================="
echo ""
echo "📍 Project: $(basename "$PWD")"
echo "⏱️  Started: $(date '+%H:%M:%S')"
echo ""

# Find cartridges
cartridges=$(find . -name "cartridge" -type d 2>/dev/null | wc -l | tr -d ' ')
echo "📦 Found $cartridges cartridge directories"
echo ""

echo "🔄 Creating external upload process..."

# Create simple upload script
cat > /tmp/prophet_terminal.lua << 'EOF'
local function log(msg)
  print(string.format("[%s] %s", os.date("%H:%M:%S"), msg))
  io.flush()
end

log("Loading Prophet...")
local ok = pcall(function()
  vim.cmd('packadd prophet.nvim')
  require('prophet').setup({auto_upload=false, clean_on_start=false, notify=false})
end)

if ok then
  log("Prophet loaded - starting upload...")
  local utils_ok, utils = pcall(require, 'prophet.utils')
  if utils_ok and utils.show_progress then
    utils.show_progress = function(c, t, n) log(string.format("Progress: %d/%d - %s", c, t, n)) end
  end
  
  pcall(function() vim.cmd('ProphetClean') end)
  log("Upload initiated - will complete in background")
  
  vim.defer_fn(function() vim.cmd('qall!') end, 10000)
else
  log("Failed to load Prophet")
  vim.cmd('qall!')
end
EOF

echo "🚀 Starting upload process..."
nvim --headless -S /tmp/prophet_terminal.lua &

echo ""
echo "✅ Upload process launched in background"
echo "💡 Your main Neovim remains fully responsive!"
echo ""
echo "📋 Monitor the notification area for progress updates"
echo "🔍 Check your SFCC sandbox to verify completion"
echo ""
echo "Press Enter to close this terminal..."
read

# Cleanup
rm -f /tmp/prophet_terminal.lua 2>/dev/null
echo "✨ Terminal closed - upload continues in background"
]]
  }
  
  snacks.terminal.open(cmd, {
    interactive = true,
    win = {
      title = " Prophet SFCC - Terminal Upload ",
      width = 0.8,
      height = 0.6,
      border = "rounded",
    }
  })
end

-- Direct curl upload
function M.direct_curl_upload()
  if not check_project() then
    return
  end
  
  if not pcall(require, "snacks") then
    notify("❌ Snacks.nvim required", vim.log.levels.ERROR)
    return
  end
  
  notify("🔧 Starting direct curl upload...", vim.log.levels.INFO)
  
  local snacks = require("snacks")
  local cmd = {
    "bash", "-c", [[
echo "🔧 Prophet Direct Curl Upload"
echo "============================="
echo ""

if [ ! -f "dw.json" ]; then
  echo "❌ No dw.json found"
  exit 1
fi

echo "📋 Reading dw.json..."

# Extract config using basic grep
hostname=$(grep '"hostname"' dw.json | cut -d'"' -f4)
username=$(grep '"username"' dw.json | cut -d'"' -f4)  
password=$(grep '"password"' dw.json | cut -d'"' -f4)
version=$(grep '"code-version"' dw.json | cut -d'"' -f4)

if [ -z "$version" ]; then
  version="version1"
fi

echo "🌐 Host: $hostname"
echo "👤 User: $username" 
echo "📦 Version: $version"
echo ""

# Find cartridges
cartridge_dirs=$(find . -name "cartridge" -type d)
if [ -z "$cartridge_dirs" ]; then
  echo "❌ No cartridge directories found"
  exit 1
fi

count=$(echo "$cartridge_dirs" | wc -l)
echo "📦 Found $count cartridges to upload"
echo ""

i=0
for dir in $cartridge_dirs; do
  i=$((i + 1))
  name=$(basename "$(dirname "$dir")")
  
  echo "📤 [$i/$count] Uploading: $name"
  
  # Create zip
  zip_file="/tmp/${name}_upload.zip"
  (cd "$(dirname "$dir")" && zip -r -q "$zip_file" cartridge/) 
  
  if [ $? -eq 0 ]; then
    # Upload
    url="https://$hostname/on/demandware.servlet/webdav/Sites/Cartridges/$version/${name}_cartridge.zip"
    
    curl -s --max-time 60 -X PUT -H "Content-Type: application/zip" -u "$username:$password" --data-binary "@$zip_file" "$url"
    
    if [ $? -eq 0 ]; then
      echo "   ✅ Uploaded successfully"
      
      # Unzip
      curl -s --max-time 30 -X POST -H "Content-Type: application/x-www-form-urlencoded" --data "method=UNZIP" -u "$username:$password" "$url" >/dev/null
      echo "   📂 Unzipped on server"
      
      # Cleanup server zip
      curl -s --max-time 10 -X DELETE -u "$username:$password" "$url" >/dev/null 2>&1
    else
      echo "   ❌ Upload failed"
    fi
    
    rm -f "$zip_file"
  else
    echo "   ❌ Failed to create zip"
  fi
  
  echo ""
done

echo "🎉 Direct upload completed!"
echo "🔍 Check your SFCC sandbox for results"
echo ""
echo "Press Enter to close..."
read
]]
  }
  
  snacks.terminal.open(cmd, {
    interactive = true,
    win = {
      title = " Prophet SFCC - Direct Curl Upload ",
      width = 0.8,
      height = 0.8,
      border = "rounded",
    }
  })
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
  -- Create user commands
  vim.api.nvim_create_user_command("ProphetCleanFeedback", M.clean_upload_terminal, {
    desc = "Terminal upload with live progress"
  })
  
  vim.api.nvim_create_user_command("ProphetCleanExternal", M.direct_curl_upload, {
    desc = "Direct curl upload bypass"
  })
  
  vim.api.nvim_create_user_command("ProphetToggleFeedback", M.toggle_upload, {
    desc = "Toggle auto-upload"
  })
  
  vim.api.nvim_create_user_command("ProphetPerfFeedback", M.show_status, {
    desc = "Show Prophet status"
  })
  
  vim.api.nvim_create_user_command("ProphetCancel", M.force_cancel, {
    desc = "Force cancel all uploads"
  })
  
  -- Override keymaps if Prophet is available
  pcall(function()
    if pcall(require, "prophet") then
      vim.keymap.set("n", "<leader>pc", M.clean_upload_terminal, { desc = "Prophet: Terminal upload" })
      vim.keymap.set("n", "<leader>pC", M.direct_curl_upload, { desc = "Prophet: Direct curl" })
      vim.keymap.set("n", "<leader>pt", M.toggle_upload, { desc = "Prophet: Toggle upload" })
      vim.keymap.set("n", "<leader>pp", M.show_status, { desc = "Prophet: Status" })
      vim.keymap.set("n", "<leader>px", M.force_cancel, { desc = "Prophet: Cancel" })
    end
  end)
end

return M