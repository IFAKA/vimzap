-- Snacks with minimal fallback
local snacks_ok, Snacks = pcall(require, "snacks")
if not snacks_ok then
  local warn = function() vim.notify("Snacks.nvim not available", vim.log.levels.WARN) end
  local noop = setmetatable({}, { __index = function() return warn end })
  Snacks = setmetatable({ picker = noop, notifier = { notify = vim.notify } }, { __index = function() return warn end })
end

-- Insert mode: jj to escape
vim.keymap.set("i", "jj", "<Esc>", { desc = "Exit insert mode" })

-- Dashboard: press 'x' to clear recent files, 'X' to clear projects
vim.api.nvim_create_autocmd("FileType", {
  pattern = "snacks_dashboard",
  callback = function(args)
    -- Clear recent files
    vim.keymap.set("n", "x", function()
      vim.ui.select({ "Yes", "No" }, { prompt = "Clear all recent files?" }, function(choice)
        if choice == "Yes" then
          vim.v.oldfiles = {}
          vim.cmd("wshada!")
          Snacks.dashboard()
        end
      end)
    end, { buffer = args.buf, desc = "Clear recent files" })

    -- Clear projects (delete the snacks projects cache)
    vim.keymap.set("n", "X", function()
      vim.ui.select({ "Yes", "No" }, { prompt = "Clear all projects?" }, function(choice)
        if choice == "Yes" then
          local projects_file = vim.fn.stdpath("data") .. "/snacks/projects.json"
          vim.fn.delete(projects_file)
          vim.v.oldfiles = {}
          vim.cmd("wshada!")
          Snacks.dashboard()
        end
      end)
    end, { buffer = args.buf, desc = "Clear projects" })
  end,
})

local function lsp_cmd(fn)
  return function()
    if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then
      fn()
    else
      Snacks.notifier.notify("No LSP attached", "warn")
    end
  end
end

local function copy_project_path()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then
    Snacks.notifier.notify("Current buffer has no file path", "warn")
    return
  end

  filepath = vim.fs.normalize(vim.fn.resolve(filepath))
  local root = vim.fs.root(0, { ".git", "package.json", "tsconfig.json", "jsconfig.json" })
    or vim.fn.getcwd()
  root = vim.fs.normalize(vim.fn.resolve(root))

  local relative = filepath
  local prefix = root .. "/"
  if filepath:sub(1, #prefix) == prefix then
    relative = filepath:sub(#prefix + 1)
  else
    Snacks.notifier.notify("File is outside the project root; copied absolute path", "warn")
  end

  vim.fn.setreg("+", relative)
  Snacks.notifier.notify("Copied: " .. relative, "info")
end

-- VS Code-style debug keys
vim.keymap.set("n", "<F5>", function() require("dap").continue() end, { desc = "Debug continue/start" })
vim.keymap.set("n", "<F9>", function() require("dap").toggle_breakpoint() end, { desc = "Debug toggle breakpoint" })
vim.keymap.set("n", "<F10>", function() require("dap").step_over() end, { desc = "Debug step over" })
vim.keymap.set("n", "<F11>", function() require("dap").step_into() end, { desc = "Debug step into" })
vim.keymap.set("n", "<S-F11>", function() require("dap").step_out() end, { desc = "Debug step out" })
vim.keymap.set("n", "<S-F5>", function() require("dap").terminate() end, { desc = "Debug terminate" })

-- LSP keymaps (on attach)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    end

    local function lsp_map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, desc = desc })
    end
    lsp_map("n", "gd", vim.lsp.buf.definition, "Go to definition")
    lsp_map("n", "gr", vim.lsp.buf.references, "Go to references")
    lsp_map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
    lsp_map("n", "gy", vim.lsp.buf.type_definition, "Go to type definition")
    lsp_map("n", "K", vim.lsp.buf.hover, "Hover documentation")
    lsp_map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature help")
  end,
})

local function map(lhs, rhs, desc, mode)
  vim.keymap.set(mode or "n", lhs, rhs, { desc = desc })
end

map("<leader>w", "<cmd>w<cr>", "Save")
map("<leader>e", function() Snacks.explorer() end, "Explorer")
map("<leader>ff", function() Snacks.picker.files() end, "Find files")
map("<leader>fg", function() Snacks.picker.grep() end, "Grep files")
map("<leader>fb", function() Snacks.picker.buffers() end, "Find buffers")
map("<leader>fc", function() Snacks.picker.git_log() end, "Git commits")
map("<leader>fr", function() Snacks.picker.recent() end, "Recent files")
map("<leader>fp", copy_project_path, "Copy project path")

map("<leader>ca", lsp_cmd(vim.lsp.buf.code_action), "Code action")
map("<leader>cr", lsp_cmd(vim.lsp.buf.rename), "Rename symbol")
map("<leader>cf", function() require("conform").format() end, "Format")
map("<leader>co", lsp_cmd(function()
  vim.lsp.buf.code_action({ apply = true, context = { only = { "source.removeUnusedImports.ts" }, diagnostics = {} } })
end), "Remove unused imports")
map("<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
map("<leader>cs", function() Snacks.picker.lsp_symbols() end, "Document symbols")

map("<leader>gg", function()
  if vim.fn.executable("lazygit") == 1 then
    vim.cmd("LazyGit")
  else
    Snacks.notifier.notify("lazygit not installed. Install: brew install lazygit", "warn")
  end
end, "Lazygit")
map("<leader>gf", function() Snacks.picker.git_files() end, "Git files")
map("<leader>gs", function() Snacks.picker.git_status() end, "Git status")
map("<leader>gp", "<cmd>Gitsigns preview_hunk<cr>", "Preview hunk")
map("<leader>ga", "<cmd>Gitsigns stage_hunk<cr>", "Stage hunk")
map("<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", "Reset hunk")
map("<leader>gb", "<cmd>Gitsigns blame_line<cr>", "Blame line")

map("<leader>sh", function() Snacks.picker.help() end, "Search help")
map("<leader>sk", function() Snacks.picker.keymaps() end, "Search keymaps")
map("<leader>sc", function() Snacks.picker.commands() end, "Search commands")
map("<leader>sd", function() Snacks.picker.diagnostics() end, "Search diagnostics")
map("<leader>sq", function() require("md-share").share() end, "Share markdown (QR)")
map("<leader>?", function() Snacks.picker.keymaps() end, "Show keymaps")
map("<leader>m", "<cmd>Mason<cr>", "Manage external tools")
map("<leader>h", "<cmd>VimZapHealth<cr>", "Health check")

map("<leader>db", function() require("dap").toggle_breakpoint() end, "Debug breakpoint")
map("<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, "Debug conditional breakpoint")
map("<leader>dc", function() require("dap").continue() end, "Debug continue/start")
map("<leader>di", function() require("dap").step_into() end, "Debug step into")
map("<leader>do", function() require("dap").step_over() end, "Debug step over")
map("<leader>dO", function() require("dap").step_out() end, "Debug step out")
map("<leader>dr", function() require("dap").restart() end, "Debug restart")
map("<leader>dq", function() require("dap").terminate() end, "Debug stop")
map("<leader>du", function() require("dapui").toggle() end, "Debug UI")
map("<leader>de", function() require("dapui").eval() end, "Debug evaluate", { "n", "v" })

map("<leader>pc", "<cmd>ProphetClean<cr>", "Prophet upload all cartridges")
map("<leader>pt", "<cmd>ProphetToggle<cr>", "Prophet toggle auto-upload")
map("<leader>ps", "<cmd>ProphetStatus<cr>", "Prophet status")
map("<leader>pe", "<cmd>ProphetEnable<cr>", "Prophet enable auto-upload")
map("<leader>pd", "<cmd>ProphetDisable<cr>", "Prophet disable auto-upload")
map("<leader>pu", "<cmd>ProphetUpload<cr>", "Prophet upload cartridge")
map("<leader>pC", "<cmd>ProphetCheckSandbox<cr>", "Prophet check sandbox")
map("<leader>pf", "<cmd>ProphetControllers<cr>", "Find SFCC controller")
map("<leader>pi", "<cmd>ProphetTemplates<cr>", "Find ISML template")
map("<leader>pl", "<cmd>ProphetLogs<cr>", "View SFCC logs")
map("<leader>pr", "<cmd>ProphetRefresh<cr>", "Refresh SFCC controllers")

map("[d", function() vim.diagnostic.jump({ count = -1 }) end, "Previous diagnostic")
map("]d", function() vim.diagnostic.jump({ count = 1 }) end, "Next diagnostic")
map("[e", function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR }) end, "Previous error")
map("]e", function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR }) end, "Next error")
map("[h", "<cmd>Gitsigns nav_hunk prev<cr>", "Previous hunk")
map("]h", "<cmd>Gitsigns nav_hunk next<cr>", "Next hunk")
map("<S-h>", "<cmd>bprevious<cr>", "Previous buffer")
map("<S-l>", "<cmd>bnext<cr>", "Next buffer")
map("<leader>bd", function() Snacks.bufdelete() end, "Delete buffer")
map("<leader>bo", "<cmd>%bd|e#|bd#<cr>", "Close other buffers")
map("<C-/>", function() Snacks.terminal() end, "Terminal", { "n", "t" })

map("<C-Space>", function() vim.lsp.completion.get() end, "Trigger LSP completion", "i")
vim.keymap.set("i", "<Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
end, { expr = true, desc = "Next completion" })
vim.keymap.set("i", "<S-Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end, { expr = true, desc = "Previous completion" })
