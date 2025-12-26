-- Helper functions
local function gitsigns_cmd(cmd)
  vim.cmd("Gitsigns " .. cmd)
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

-- LSP keymaps (on attach)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local opts = { buffer = args.buf }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, opts)
  end,
})

-- Which-key mappings
require("which-key").add({
  -- Save
  { "<leader>w", "<cmd>w<cr>", desc = "save" },

  -- Explorer
  { "<leader>e", function() Snacks.explorer() end, desc = "explorer" },

  -- File
  { "<leader>f", group = "file" },
  { "<leader>ff", function() Snacks.picker.files() end, desc = "find" },
  { "<leader>fg", function() Snacks.picker.grep() end, desc = "grep" },
  { "<leader>fb", function() Snacks.picker.buffers() end, desc = "buffers" },
  { "<leader>fr", function() Snacks.picker.recent() end, desc = "recent" },

  -- Code
  { "<leader>c", group = "code" },
  { "<leader>ca", lsp_cmd(vim.lsp.buf.code_action), desc = "action" },
  { "<leader>cr", lsp_cmd(vim.lsp.buf.rename), desc = "rename" },
  { "<leader>cf", function() require("conform").format() end, desc = "format" },
  { "<leader>co", lsp_cmd(function()
      vim.lsp.buf.code_action({ apply = true, context = { only = { "source.removeUnusedImports.ts" }, diagnostics = {} } })
    end), desc = "remove unused imports" },
  { "<leader>cd", vim.diagnostic.open_float, desc = "diagnostic" },
  { "<leader>cs", function() Snacks.picker.lsp_symbols() end, desc = "symbols" },

  -- Git
  { "<leader>g", group = "git" },
  { "<leader>gg", function()
      if vim.fn.executable("lazygit") == 1 then
        vim.cmd("LazyGit")
      else
        Snacks.notifier.notify("lazygit not installed. Install: brew install lazygit", "warn")
      end
    end, desc = "lazygit" },
  { "<leader>gf", function() Snacks.picker.git_files() end, desc = "git files" },
  { "<leader>gs", function() Snacks.picker.git_status() end, desc = "status" },
  { "<leader>gp", function() gitsigns_cmd("preview_hunk") end, desc = "preview hunk" },
  { "<leader>ga", function() gitsigns_cmd("stage_hunk") end, desc = "stage hunk" },
  { "<leader>gr", function() gitsigns_cmd("reset_hunk") end, desc = "reset hunk" },
  { "<leader>gb", function() gitsigns_cmd("blame_line") end, desc = "blame" },

  -- Search
  { "<leader>s", group = "search" },
  { "<leader>sh", function() Snacks.picker.help() end, desc = "help" },
  { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "keymaps" },
  { "<leader>sc", function() Snacks.picker.commands() end, desc = "commands" },
  { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "diagnostics" },
  { "<leader>sq", function() require("md-share").share() end, desc = "share markdown (QR)" },

  -- Mason
  { "<leader>m", ":Mason<CR>", desc = "mason (LSP manager)" },

  -- Help
  { "<leader>?", function() Snacks.picker.keymaps() end, desc = "keymaps" },

  -- Health Check (includes performance metrics)
  { "<leader>h", function() require("health").run() end, desc = "health check" },

  -- Debug
  { "<leader>d", group = "debug" },
  { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "breakpoint" },
  { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, desc = "conditional breakpoint" },
  { "<leader>dc", function() require("dap").continue() end, desc = "continue/start" },
  { "<leader>di", function() require("dap").step_into() end, desc = "step into" },
  { "<leader>do", function() require("dap").step_over() end, desc = "step over" },
  { "<leader>dO", function() require("dap").step_out() end, desc = "step out" },
  { "<leader>dr", function() require("dap").restart() end, desc = "restart" },
  { "<leader>dq", function() require("dap").terminate() end, desc = "quit/stop" },
  { "<leader>du", function() require("dapui").toggle() end, desc = "toggle UI" },
  { "<leader>de", function() require("dapui").eval() end, desc = "eval", mode = { "n", "v" } },

  -- Prophet (SFCC Development)
  { "<leader>p", group = "prophet" },
  { "<leader>pe", "<cmd>ProphetEnable<cr>", desc = "enable auto-upload" },
  { "<leader>pd", "<cmd>ProphetDisable<cr>", desc = "disable auto-upload" },
  { "<leader>pt", "<cmd>ProphetToggle<cr>", desc = "toggle auto-upload" },
  { "<leader>pc", "<cmd>ProphetClean<cr>", desc = "clean upload all" },

  -- Navigation
  { "[d", vim.diagnostic.goto_prev, desc = "prev diagnostic" },
  { "]d", vim.diagnostic.goto_next, desc = "next diagnostic" },
  { "[e", function()
      vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
    end, desc = "prev error" },
  { "]e", function()
      vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
    end, desc = "next error" },
  { "[h", function() gitsigns_cmd("nav_hunk prev") end, desc = "prev hunk" },
  { "]h", function() gitsigns_cmd("nav_hunk next") end, desc = "next hunk" },

  -- Buffer navigation
  { "<S-h>", "<cmd>bprevious<cr>", desc = "prev buffer" },
  { "<S-l>", "<cmd>bnext<cr>", desc = "next buffer" },
  { "<leader>bd", function() Snacks.bufdelete() end, desc = "delete buffer" },
  { "<leader>bo", "<cmd>%bd|e#|bd#<cr>", desc = "close other buffers" },

  -- Terminal
  { "<C-/>", function() Snacks.terminal() end, desc = "terminal", mode = { "n", "t" } },
})
