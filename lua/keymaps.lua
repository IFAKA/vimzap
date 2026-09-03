local function map(lhs, rhs, desc, mode)
  vim.keymap.set(mode or "n", lhs, rhs, { desc = desc })
end

local function select_item(items, prompt, format_item, on_choice)
  vim.ui.select(items, { prompt = prompt, format_item = format_item }, on_choice)
end

local function project_root()
  return vim.fs.root(0, { ".git", "package.json", "tsconfig.json", "jsconfig.json" }) or vim.fn.getcwd()
end

local function files()
  local root = project_root()
  local candidates = vim.fn.globpath(root, "**/*", false, true)
  candidates = vim.tbl_filter(function(path)
    return vim.fn.isdirectory(path) == 0
      and not path:match("/%.git/")
      and not path:match("/node_modules/")
  end, candidates)
  table.sort(candidates)
  select_item(candidates, "Files", function(path) return vim.fn.fnamemodify(path, ":.") end, function(path)
    if path then vim.cmd.edit(vim.fn.fnameescape(path)) end
  end)
end

local function grep()
  local query = vim.fn.input("Grep: ")
  if query == "" then return end
  vim.cmd("silent! noautocmd vimgrep /" .. vim.fn.escape(query, "/") .. "/gj **/*")
  vim.cmd("copen")
end

local function buffers()
  local items = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted then
      local name = vim.api.nvim_buf_get_name(bufnr)
      table.insert(items, { bufnr = bufnr, name = name == "" and "[No Name]" or name })
    end
  end
  select_item(items, "Buffers", function(item) return item.bufnr .. "  " .. item.name end, function(item)
    if item then vim.api.nvim_set_current_buf(item.bufnr) end
  end)
end

local function recent_files()
  local items = vim.tbl_filter(function(path) return vim.fn.filereadable(path) == 1 end, vim.v.oldfiles)
  select_item(items, "Recent files", function(path) return vim.fn.fnamemodify(path, ":~:.") end, function(path)
    if path then vim.cmd.edit(vim.fn.fnameescape(path)) end
  end)
end

local function git_command(command)
  vim.cmd("botright split | terminal git " .. command)
  vim.cmd("startinsert")
end

local function copy_project_path()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then return end
  filepath = vim.fs.normalize(vim.fn.resolve(filepath))
  local root = vim.fs.normalize(vim.fn.resolve(project_root()))
  local prefix = root .. "/"
  local relative = filepath:sub(1, #prefix) == prefix and filepath:sub(#prefix + 1) or filepath
  vim.fn.setreg("+", relative)
  vim.notify("Copied: " .. relative)
end

local function toggle_terminal()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "terminal" then
      vim.api.nvim_win_close(win, false)
      return
    end
  end
  vim.cmd("botright split | terminal")
  vim.cmd("startinsert")
end

local function lsp_cmd(fn)
  return function()
    if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then fn() end
  end
end

local function dap_action(method)
  return function()
    require("vimzap.debug").setup()
    require("dap")[method]()
  end
end

vim.api.nvim_create_user_command("VimZapFiles", files, {})
vim.api.nvim_create_user_command("VimZapGrep", grep, {})
vim.api.nvim_create_user_command("VimZapBuffers", buffers, {})
vim.api.nvim_create_user_command("VimZapRecent", recent_files, {})

map("<leader>w", "<cmd>w<cr>", "Save")
map("<leader>ff", files, "Find files")
map("<leader>fg", grep, "Grep project")
map("<leader>fb", buffers, "Find buffers")
map("<leader>fr", recent_files, "Recent files")
map("<leader>fp", copy_project_path, "Copy project path")
map("<leader>ca", lsp_cmd(vim.lsp.buf.code_action), "Code action")
map("<leader>cr", lsp_cmd(vim.lsp.buf.rename), "Rename symbol")
map("<leader>cf", lsp_cmd(function() vim.lsp.buf.format({ async = true }) end), "Format")
map("<leader>co", lsp_cmd(function()
  vim.lsp.buf.code_action({ apply = true, context = { only = { "source.removeUnusedImports.ts" }, diagnostics = {} } })
end), "Remove unused imports")
map("<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
map("<leader>cs", lsp_cmd(vim.lsp.buf.document_symbol), "Document symbols")
map("<leader>gf", function() git_command("ls-files") end, "Git files")
map("<leader>gs", function() git_command("status") end, "Git status")
map("<leader>gc", function() git_command("log --oneline --decorate -20") end, "Git commits")
map("<leader>gp", "<cmd>Gitsigns preview_hunk<cr>", "Preview hunk")
map("<leader>ga", "<cmd>Gitsigns stage_hunk<cr>", "Stage hunk")
map("<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", "Reset hunk")
map("<leader>gb", "<cmd>Gitsigns blame_line<cr>", "Blame line")
map("<leader>sh", "<cmd>help<cr>", "Open help")
map("<leader>sk", "<cmd>map<cr>", "Show keymaps")
map("<leader>sc", "<cmd>command<cr>", "Show commands")
map("<leader>sd", vim.diagnostic.setqflist, "Diagnostics quickfix")
map("<leader>?", "<cmd>map<cr>", "Show keymaps")
map("<leader>db", dap_action("toggle_breakpoint"), "Debug breakpoint")
map("<leader>dB", function() require("vimzap.debug").setup(); require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, "Debug conditional breakpoint")
map("<leader>dc", dap_action("continue"), "Debug continue/start")
map("<leader>di", dap_action("step_into"), "Debug step into")
map("<leader>do", dap_action("step_over"), "Debug step over")
map("<leader>dO", dap_action("step_out"), "Debug step out")
map("<leader>dr", dap_action("restart"), "Debug restart")
map("<leader>dq", dap_action("terminate"), "Debug stop")
map("<leader>du", function() require("vimzap.debug").setup(); require("dapui").toggle() end, "Debug UI")
map("<leader>de", function() require("vimzap.debug").setup(); require("dapui").eval() end, "Debug evaluate", { "n", "v" })
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
