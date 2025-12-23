-- LSP capabilities (with completion support)
local function get_capabilities()
  local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
  if ok then
    return cmp_lsp.default_capabilities()
  end
  return vim.lsp.protocol.make_client_capabilities()
end

-- LSP servers (Neovim 0.11+ native)
vim.lsp.config("ts_ls", {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  root_dir = function(fname)
    return vim.fs.root(fname, { "tsconfig.json", "jsconfig.json", "package.json", ".git" })
  end,
  capabilities = get_capabilities(),
})

vim.lsp.config("html", {
  cmd = { "vscode-html-language-server", "--stdio" },
  filetypes = { "html" },
  root_dir = function(fname)
    return vim.fs.root(fname, { "package.json", ".git" })
  end,
  capabilities = get_capabilities(),
})

vim.lsp.config("cssls", {
  cmd = { "vscode-css-language-server", "--stdio" },
  filetypes = { "css", "scss" },
  root_dir = function(fname)
    return vim.fs.root(fname, { "package.json", ".git" })
  end,
  capabilities = get_capabilities(),
})

vim.lsp.config("jsonls", {
  cmd = { "vscode-json-language-server", "--stdio" },
  filetypes = { "json", "jsonc" },
  root_dir = function(fname)
    return vim.fs.root(fname, { ".git" })
  end,
  capabilities = get_capabilities(),
})

vim.lsp.config("tailwindcss", {
  cmd = { "tailwindcss-language-server", "--stdio" },
  filetypes = { "typescriptreact", "javascriptreact", "html", "css" },
  root_dir = function(fname)
    return vim.fs.root(fname, {
      "tailwind.config.js",
      "tailwind.config.ts",
      "tailwind.config.mjs",
      "tailwind.config.cjs",
      "postcss.config.js",
      "postcss.config.mjs",  -- Tailwind v4
      "package.json",
    })
  end,
  capabilities = get_capabilities(),
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

vim.lsp.config("eslint", {
  cmd = { "vscode-eslint-language-server", "--stdio" },
  filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  root_dir = function(fname)
    return vim.fs.root(fname, { "eslint.config.mjs", "eslint.config.js", ".eslintrc.js", ".eslintrc.json", "package.json" })
  end,
  capabilities = get_capabilities(),
  settings = {
    validate = "on",
    experimental = { useFlatConfig = true },
    rulesCustomizations = {},
    run = "onType",
    problems = { shortenToSingleLine = false },
    nodePath = "",
  },
  init_options = {
    documentFormatting = false, -- Let Prettier handle formatting
  },
})

vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_dir = function(fname)
    return vim.fs.root(fname, { ".luarc.json", ".luarc.jsonc", ".luacheckrc", ".stylua.toml", "stylua.toml", ".git" })
  end,
  capabilities = get_capabilities(),
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
      },
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      telemetry = {
        enable = false,
      },
    },
  },
})

vim.lsp.enable({ "ts_ls", "html", "cssls", "jsonls", "tailwindcss", "eslint", "lua_ls" })

-- Format on save (all file types handled by conform)
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function(args)
    require("conform").format({ bufnr = args.buf, async = false, timeout_ms = 3000 })
  end,
})
