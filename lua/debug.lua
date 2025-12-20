-- Debug (nvim-dap)
vim.cmd[[packadd nvim-dap]]
vim.cmd[[packadd nvim-dap-ui]]
vim.cmd[[packadd nvim-nio]]

local dap = require("dap")
local dapui = require("dapui")

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

dap.configurations.javascript = js_config
dap.configurations.typescript = js_config
dap.configurations.javascriptreact = js_config
dap.configurations.typescriptreact = js_config
