-- LSP configuration and activation.
-- nvim-lspconfig supplies server defaults; Neovim owns the client.

local typescript_language_server = vim.fn.exepath("typescript-language-server")
local npm_command = "npm"
if vim.fn.executable("brew") == 1 then
  local brew_bin = vim.fn.system({ "brew", "--prefix" }):gsub("%s+$", "") .. "/bin"
  local brew_tsls = brew_bin .. "/typescript-language-server"
  if vim.fn.executable(brew_tsls) == 1 then
    typescript_language_server = brew_tsls
    npm_command = brew_bin .. "/npm"
  end
end

local global_typescript
local global_tsserver
if vim.fn.executable(npm_command) == 1 then
  local npm_root = vim.fn.system({ npm_command, "root", "-g" }):gsub("%s+$", "")
  local candidate = npm_root .. "/typescript/lib"
  local tsserver = candidate .. "/tsserver.js"
  if vim.fn.isdirectory(candidate) == 1 and vim.fn.filereadable(tsserver) == 1 then
    global_typescript = candidate
    global_tsserver = tsserver
  end
end

vim.lsp.config("ts_ls", {
  -- Prefer workspace TypeScript; use the global installation as fallback.
  cmd = typescript_language_server ~= "" and { typescript_language_server, "--stdio" } or nil,
  init_options = {
    preferences = { includePackageJsonAutoImports = "auto" },
    tsserver = global_tsserver and {
      path = global_tsserver,
      fallbackPath = global_typescript,
    } or nil,
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
