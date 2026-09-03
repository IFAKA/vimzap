-- LSP configuration and activation.
-- nvim-lspconfig supplies server defaults; Neovim owns the client.

local global_typescript
if vim.fn.executable("npm") == 1 then
  local npm_root = vim.fn.system({ "npm", "root", "-g" }):gsub("%s+$", "")
  local candidate = npm_root .. "/typescript/lib"
  if vim.fn.isdirectory(candidate) == 1 then global_typescript = candidate end
end

vim.lsp.config("ts_ls", {
  -- Prefer workspace TypeScript; use the global installation as fallback.
  init_options = {
    preferences = { includePackageJsonAutoImports = "auto" },
    tsserver = global_typescript and { fallbackPath = global_typescript } or nil,
  },
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
