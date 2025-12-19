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
  root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
  capabilities = get_capabilities(),
})

vim.lsp.config("html", {
  cmd = { "vscode-html-language-server", "--stdio" },
  filetypes = { "html" },
  root_markers = { "package.json", ".git" },
  capabilities = get_capabilities(),
})

vim.lsp.config("cssls", {
  cmd = { "vscode-css-language-server", "--stdio" },
  filetypes = { "css", "scss" },
  root_markers = { "package.json", ".git" },
  capabilities = get_capabilities(),
})

vim.lsp.config("jsonls", {
  cmd = { "vscode-json-language-server", "--stdio" },
  filetypes = { "json", "jsonc" },
  root_markers = { ".git" },
  capabilities = get_capabilities(),
})

vim.lsp.config("tailwindcss", {
  cmd = { "tailwindcss-language-server", "--stdio" },
  filetypes = { "typescriptreact", "javascriptreact", "html", "css" },
  root_markers = {
    "tailwind.config.js",
    "tailwind.config.ts",
    "tailwind.config.mjs",
    "tailwind.config.cjs",
    "postcss.config.js",
    "postcss.config.mjs",  -- Tailwind v4
    "package.json",
  },
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
  root_markers = { "eslint.config.mjs", "eslint.config.js", ".eslintrc.js", ".eslintrc.json", "package.json" },
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
    documentFormatting = true,
    codeActionOnSave = { mode = "all" },
  },
})

vim.lsp.enable({ "ts_ls", "html", "cssls", "jsonls", "tailwindcss", "eslint" })

-- Remove unused imports + format on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
  callback = function()
    -- Remove unused imports
    vim.lsp.buf.code_action({
      apply = true,
      context = { only = { "source.removeUnusedImports.ts" }, diagnostics = {} },
    })
    -- Format with prettier via conform
    require("conform").format({ async = false, timeout_ms = 3000 })
  end,
})
