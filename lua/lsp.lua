-- LSP configuration and activation.
-- nvim-lspconfig supplies server defaults; Neovim owns the client.

vim.lsp.config("ts_ls", {
  -- Use the workspace TypeScript version when one is installed.
  on_new_config = function(config, root_dir)
    local local_ts = root_dir and (root_dir .. "/node_modules/typescript/lib")
    local global_ts
    if vim.fn.executable("npm") == 1 then
      local npm_root = vim.fn.system({ "npm", "root", "-g" }):gsub("%s+$", "")
      global_ts = npm_root .. "/typescript/lib"
    end
    config.init_options = {
      preferences = { includePackageJsonAutoImports = "auto" },
    }

    if local_ts and vim.fn.isdirectory(local_ts) == 1 then
      config.init_options.tsserver = { path = local_ts }
    elseif global_ts and vim.fn.isdirectory(global_ts) == 1 then
      config.init_options.tsserver = { path = global_ts }
    end
  end,
})

vim.lsp.config("eslint", {
  init_options = {
    documentFormatting = false,
  },
})

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      diagnostics = { globals = { "vim" } },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      telemetry = { enable = false },
    },
  },
})

vim.lsp.config("tailwindcss", {
  settings = {
    tailwindCSS = {
      experimental = {
        classRegex = {
          { "class:\\s*\"([^\"]*)\"" },
          { "className:\\s*\"([^\"]*)\"" },
          { "className={\"([^\"}]*)\"}" },
        },
      },
    },
  },
})

vim.lsp.enable({
  "ts_ls",
  "html",
  "cssls",
  "jsonls",
  "tailwindcss",
  "eslint",
  "lua_ls",
  "pyright",
  "gopls",
  "clangd",
  "rust_analyzer",
})
