-- Debug (nvim-dap)
-- Only load if DAP plugins are available
local dap_ok = pcall(function() vim.cmd[[packadd nvim-dap]] end)
local dapui_ok = pcall(function() vim.cmd[[packadd nvim-dap-ui]] end)
local nio_ok = pcall(function() vim.cmd[[packadd nvim-nio]] end)

if not (dap_ok and dapui_ok and nio_ok) then
  return -- Exit early if DAP plugins aren't available
end

local dap = require("dap")
local dapui = require("dapui")

local function notify_warn(message)
  vim.schedule(function()
    vim.notify(message, vim.log.levels.WARN, { title = "nvim-dap" })
  end)
end

-- UI setup
dapui.setup({
  layouts = {
    {
      elements = {
        { id = "scopes", size = 0.5 },
        { id = "breakpoints", size = 0.25 },
        { id = "stacks", size = 0.25 },
      },
      size = 40,
      position = "left",
    },
    {
      elements = { "repl", "console" },
      size = 0.25,
      position = "bottom",
    },
  },
})

-- Auto open/close UI
dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

-- Signs
vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "CursorLine" })

-- Node.js adapter (uses vscode-js-debug via Mason)
dap.adapters["pwa-node"] = {
  type = "server",
  host = "localhost",
  port = "${port}",
  executable = {
    command = "node",
    args = {
      vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js",
      "${port}",
    },
  },
}

-- Prophet adapter (SFCC server-side debugging via the local VS Code extension)
local function find_prophet_adapter()
  local extension_root = vim.fn.expand("~/.vscode/extensions")
  local prophet_extensions = vim.fn.globpath(extension_root, "sqrtt.prophet-*", false, true)

  if #prophet_extensions == 0 then
    return nil
  end

  table.sort(prophet_extensions)

  for i = #prophet_extensions, 1, -1 do
    local adapter_path = prophet_extensions[i] .. "/dist/mockDebug.js"
    if vim.fn.filereadable(adapter_path) == 1 then
      return adapter_path
    end
  end

  return nil
end

local prophet_adapter = find_prophet_adapter()
local sfcc_config = nil

if prophet_adapter then
  dap.adapters.prophet = {
    type = "executable",
    command = "node",
    args = { prophet_adapter },
  }

  sfcc_config = {
    type = "prophet",
    request = "attach",
    name = "Attach to SFCC Sandbox",
    cwd = "${workspaceFolder}",
    trace = true,
  }
else
  notify_warn("Prophet VS Code extension not found at ~/.vscode/extensions/sqrtt.prophet-*; SFCC debugging disabled")
end

-- Configurations for JS/TS
local js_config = {
  {
    type = "pwa-node",
    request = "attach",
    name = "Attach to Node (port 9229)",
    port = 9229,
    cwd = "${workspaceFolder}",
    sourceMaps = true,
    resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" },
    skipFiles = { "<node_internals>/**", "**/node_modules/**" },
  },
  {
    type = "pwa-node",
    request = "launch",
    name = "Launch current file",
    program = "${file}",
    cwd = "${workspaceFolder}",
    sourceMaps = true,
  },
  {
    type = "pwa-node",
    request = "launch",
    name = "Launch Node (ask for file)",
    program = function()
      return vim.fn.input("Path to file: ", vim.fn.getcwd() .. "/", "file")
    end,
    cwd = "${workspaceFolder}",
    sourceMaps = true,
  },
}

local javascript_config = js_config

if sfcc_config then
  javascript_config = { sfcc_config }
  vim.list_extend(javascript_config, js_config)
  dap.configurations.dwscript = { sfcc_config }
end

dap.configurations.javascript = javascript_config
dap.configurations.typescript = js_config
dap.configurations.javascriptreact = js_config
dap.configurations.typescriptreact = js_config
