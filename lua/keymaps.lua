-- Helper functions
local function gitsigns_cmd(cmd)
  vim.cmd("Gitsigns " .. cmd)
end

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
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
  end,
})

-- Which-key mappings
require("which-key").add({
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
  { "<leader>cf", lsp_cmd(function() vim.lsp.buf.format() end), desc = "format" },
  { "<leader>cd", vim.diagnostic.open_float, desc = "diagnostic" },
  { "<leader>cs", function() Snacks.picker.lsp_symbols() end, desc = "symbols" },

  -- Git
  { "<leader>g", group = "git" },
  { "<leader>gg", ":LazyGit<CR>", desc = "lazygit" },
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

  -- Mason
  { "<leader>m", ":Mason<CR>", desc = "mason (LSP manager)" },

  -- Help
  { "<leader>?", function() Snacks.picker.keymaps() end, desc = "keymaps" },

  -- Navigation
  { "[d", vim.diagnostic.goto_prev, desc = "prev diagnostic" },
  { "]d", vim.diagnostic.goto_next, desc = "next diagnostic" },
  { "[h", function() gitsigns_cmd("nav_hunk prev") end, desc = "prev hunk" },
  { "]h", function() gitsigns_cmd("nav_hunk next") end, desc = "next hunk" },
})
