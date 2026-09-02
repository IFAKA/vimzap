local function map(lhs, rhs, desc, mode) vim.keymap.set(mode or "n", lhs, rhs, { desc = desc }) end
local function picker(method) return function() require("mini.pick").builtin[method]() end end
local function lsp_cmd(fn) return function() if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then fn() end end end

local function copy_project_path()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then return end
  filepath = vim.fs.normalize(vim.fn.resolve(filepath))
  local root = vim.fs.root(0, { ".git", "package.json", "tsconfig.json", "jsconfig.json" }) or vim.fn.getcwd()
  root = vim.fs.normalize(vim.fn.resolve(root))
  local prefix = root .. "/"
  local relative = filepath:sub(1, #prefix) == prefix and filepath:sub(#prefix + 1) or filepath
  vim.fn.setreg("+", relative)
  vim.notify("Copied: " .. relative)
end

local function toggle_terminal()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "terminal" then vim.api.nvim_win_close(win, false); return end
  end
  vim.cmd("botright split | terminal")
  vim.cmd("startinsert")
end

map("<leader>w", "<cmd>w<cr>", "Save")
map("<leader>ff", picker("files"), "Find files")
map("<leader>fg", picker("grep_live"), "Grep project")
map("<leader>fb", picker("buffers"), "Find buffers")
map("<leader>fc", picker("git_log"), "Git commits")
map("<leader>fr", picker("oldfiles"), "Recent files")
map("<leader>fp", copy_project_path, "Copy project path")
map("<leader>ca", lsp_cmd(vim.lsp.buf.code_action), "Code action")
map("<leader>cr", lsp_cmd(vim.lsp.buf.rename), "Rename symbol")
map("<leader>cf", function() require("conform").format() end, "Format")
map("<leader>co", lsp_cmd(function() vim.lsp.buf.code_action({ apply = true, context = { only = { "source.removeUnusedImports.ts" }, diagnostics = {} } }) end), "Remove unused imports")
map("<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
map("<leader>cs", picker("lsp"), "Document symbols")
map("<leader>gf", picker("git_files"), "Git files")
map("<leader>gs", picker("git_status"), "Git status")
map("<leader>gp", "<cmd>Gitsigns preview_hunk<cr>", "Preview hunk")
map("<leader>ga", "<cmd>Gitsigns stage_hunk<cr>", "Stage hunk")
map("<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", "Reset hunk")
map("<leader>gb", "<cmd>Gitsigns blame_line<cr>", "Blame line")
map("<leader>sh", picker("help"), "Search help")
map("<leader>sk", picker("keymaps"), "Search keymaps")
map("<leader>sc", picker("commands"), "Search commands")
map("<leader>sd", picker("diagnostic"), "Search diagnostics")
map("<leader>?", picker("keymaps"), "Show keymaps")
map("<leader>m", "<cmd>Mason<cr>", "Manage external tools")
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
map("<leader>bd", "<cmd>bdelete<cr>", "Delete buffer")
map("<leader>bo", "<cmd>%bd|e#|bd#<cr>", "Close other buffers")
map("<C-/>", toggle_terminal, "Terminal", { "n", "t" })
map("<C-Space>", function() vim.lsp.completion.get() end, "Trigger LSP completion", "i")

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    if client:supports_method("textDocument/completion") then vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true }) end
    local function lsp_map(mode, lhs, rhs, desc) vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, desc = desc }) end
    lsp_map("n", "gd", vim.lsp.buf.definition, "Go to definition")
    lsp_map("n", "gr", vim.lsp.buf.references, "Go to references")
    lsp_map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
    lsp_map("n", "gy", vim.lsp.buf.type_definition, "Go to type definition")
    lsp_map("n", "K", vim.lsp.buf.hover, "Hover documentation")
    lsp_map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature help")
  end,
})
