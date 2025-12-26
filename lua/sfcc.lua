-- SFCC (Salesforce Commerce Cloud) utilities for VimZap
-- Provides controller picker, SFCC completions, and utilities

local M = {}

-- Cache for controllers
M._controllers_cache = nil
M._cache_time = 0
local CACHE_TTL = 30000 -- 30 seconds

-- Find all SFCC controllers in the workspace
function M.find_controllers()
  local now = vim.loop.now()
  if M._controllers_cache and (now - M._cache_time) < CACHE_TTL then
    return M._controllers_cache
  end

  local controllers = {}
  local cwd = vim.fn.getcwd()

  -- Find all controller files (*.js in controllers directories)
  local handle = io.popen('find "' .. cwd .. '" -path "*/cartridge/controllers/*.js" -type f 2>/dev/null')
  if not handle then return controllers end

  for file in handle:lines() do
    local content = vim.fn.readfile(file)
    local endpoints = {}

    -- Parse server.get/post/append/prepend/replace calls
    for i, line in ipairs(content) do
      local method, name = line:match("server%.(%w+)%s*%(%s*['\"]([^'\"]+)['\"]")
      if method and name then
        table.insert(endpoints, {
          name = name,
          method = method:upper(),
          line = i,
        })
      end
    end

    if #endpoints > 0 then
      local relative = file:gsub(cwd .. "/", "")
      local controller_name = vim.fn.fnamemodify(file, ":t:r")
      table.insert(controllers, {
        name = controller_name,
        file = file,
        relative = relative,
        endpoints = endpoints,
      })
    end
  end
  handle:close()

  M._controllers_cache = controllers
  M._cache_time = now
  return controllers
end

-- Controller picker (like VSCode's Ctrl+F7)
function M.controller_picker()
  local snacks_ok, Snacks = pcall(require, "snacks")
  if not snacks_ok then
    vim.notify("Snacks.nvim required for controller picker", vim.log.levels.ERROR)
    return
  end

  local controllers = M.find_controllers()
  if #controllers == 0 then
    vim.notify("No SFCC controllers found in workspace", vim.log.levels.WARN)
    return
  end

  -- Build items for picker
  local items = {}
  for _, ctrl in ipairs(controllers) do
    for _, endpoint in ipairs(ctrl.endpoints) do
      table.insert(items, {
        text = string.format("[%s] %s-%s", endpoint.method, ctrl.name, endpoint.name),
        file = ctrl.file,
        line = endpoint.line,
        controller = ctrl.name,
        endpoint = endpoint.name,
        method = endpoint.method,
      })
    end
  end

  -- Sort alphabetically
  table.sort(items, function(a, b) return a.text < b.text end)

  Snacks.picker({
    title = "SFCC Controllers",
    items = items,
    format = function(item)
      return {
        { item.method, "Special" },
        { " " },
        { item.controller, "Function" },
        { "-" },
        { item.endpoint, "Identifier" },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.cmd("edit " .. item.file)
        vim.cmd(":" .. item.line)
        vim.cmd("normal! zz")
      end
    end,
  })
end

-- SFCC nvim-cmp source
M.cmp_source = {}

function M.cmp_source.new()
  return setmetatable({}, { __index = M.cmp_source })
end

function M.cmp_source:get_trigger_characters()
  return { ".", "(", '"', "'" }
end

function M.cmp_source:complete(params, callback)
  local items = {}
  local line = params.context.cursor_before_line

  -- Resource.msg completions
  if line:match("Resource%.msg[f]?%s*%($") or line:match("Resource%.msg[f]?%s*%(['\"]$") then
    table.insert(items, { label = "Resource.msg", kind = 3, insertText = "Resource.msg('${1:key}', '${2:bundle}', null)" })
    table.insert(items, { label = "Resource.msgf", kind = 3, insertText = "Resource.msgf('${1:key}', '${2:bundle}', null, ${3:args})" })
  end

  -- URLUtils completions
  if line:match("URLUtils%.$") then
    table.insert(items, { label = "url", kind = 3, documentation = "Generate relative URL" })
    table.insert(items, { label = "http", kind = 3, documentation = "Generate HTTP URL" })
    table.insert(items, { label = "https", kind = 3, documentation = "Generate HTTPS URL" })
    table.insert(items, { label = "abs", kind = 3, documentation = "Generate absolute URL" })
    table.insert(items, { label = "home", kind = 3, documentation = "Home page URL" })
    table.insert(items, { label = "staticURL", kind = 3, documentation = "Static resource URL" })
    table.insert(items, { label = "webRoot", kind = 3, documentation = "Web root URL" })
    table.insert(items, { label = "imageURL", kind = 3, documentation = "Image URL" })
  end

  -- require('dw/*') completions
  if line:match("require%s*%(['\"]dw/$") or line:match("require%s*%(['\"]dw/[^/]*$") then
    local dw_modules = {
      "catalog", "content", "crypto", "customer", "extensions",
      "i18n", "io", "net", "object", "order", "rpc", "system",
      "template", "util", "value", "web", "ws"
    }
    for _, mod in ipairs(dw_modules) do
      table.insert(items, { label = "dw/" .. mod, kind = 9, documentation = "SFCC " .. mod .. " module" })
    end
  end

  -- server.* completions
  if line:match("server%.$") then
    table.insert(items, { label = "get", kind = 3, documentation = "Register GET endpoint" })
    table.insert(items, { label = "post", kind = 3, documentation = "Register POST endpoint" })
    table.insert(items, { label = "append", kind = 3, documentation = "Append to existing endpoint" })
    table.insert(items, { label = "prepend", kind = 3, documentation = "Prepend to existing endpoint" })
    table.insert(items, { label = "replace", kind = 3, documentation = "Replace existing endpoint" })
    table.insert(items, { label = "use", kind = 3, documentation = "Apply middleware" })
    table.insert(items, { label = "exports", kind = 3, documentation = "Export server" })
  end

  -- res.* completions
  if line:match("res%.$") then
    table.insert(items, { label = "render", kind = 3, documentation = "Render ISML template" })
    table.insert(items, { label = "json", kind = 3, documentation = "Return JSON response" })
    table.insert(items, { label = "redirect", kind = 3, documentation = "Redirect to URL" })
    table.insert(items, { label = "setViewData", kind = 3, documentation = "Set template data" })
    table.insert(items, { label = "getViewData", kind = 3, documentation = "Get template data" })
    table.insert(items, { label = "setStatusCode", kind = 3, documentation = "Set HTTP status" })
    table.insert(items, { label = "cachePeriod", kind = 3, documentation = "Set cache period" })
    table.insert(items, { label = "cacheExpiration", kind = 3, documentation = "Set cache expiration" })
    table.insert(items, { label = "print", kind = 3, documentation = "Print to response" })
  end

  -- Transaction completions
  if line:match("Transaction%.$") then
    table.insert(items, { label = "wrap", kind = 3, documentation = "Wrap in transaction" })
    table.insert(items, { label = "begin", kind = 3, documentation = "Begin transaction" })
    table.insert(items, { label = "commit", kind = 3, documentation = "Commit transaction" })
    table.insert(items, { label = "rollback", kind = 3, documentation = "Rollback transaction" })
  end

  callback({ items = items, isIncomplete = false })
end

function M.cmp_source:get_keyword_pattern()
  return [[\k\+]]
end

-- Register cmp source
function M.setup_completions()
  local cmp_ok, cmp = pcall(require, "cmp")
  if cmp_ok then
    cmp.register_source("sfcc", M.cmp_source.new())
  end
end

-- Clear controller cache
function M.refresh_controllers()
  M._controllers_cache = nil
  M._cache_time = 0
  vim.notify("SFCC controller cache cleared", vim.log.levels.INFO)
end

-- Template picker (find ISML templates)
function M.template_picker()
  local snacks_ok, Snacks = pcall(require, "snacks")
  if not snacks_ok then
    vim.notify("Snacks.nvim required for template picker", vim.log.levels.ERROR)
    return
  end

  local cwd = vim.fn.getcwd()
  local templates = {}

  local handle = io.popen('find "' .. cwd .. '" -name "*.isml" -type f 2>/dev/null')
  if handle then
    for file in handle:lines() do
      local relative = file:gsub(cwd .. "/", "")
      local name = vim.fn.fnamemodify(file, ":t:r")
      table.insert(templates, {
        text = name .. " - " .. relative,
        file = file,
        name = name,
        relative = relative,
      })
    end
    handle:close()
  end

  if #templates == 0 then
    vim.notify("No ISML templates found", vim.log.levels.WARN)
    return
  end

  Snacks.picker({
    title = "ISML Templates",
    items = templates,
    format = function(item)
      return {
        { item.name, "Function" },
        { " - ", "Comment" },
        { item.relative, "Comment" },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.cmd("edit " .. item.file)
      end
    end,
  })
end

-- Log viewer (simplified - opens logs directory)
function M.view_logs()
  local snacks_ok, Snacks = pcall(require, "snacks")
  if not snacks_ok then
    vim.notify("Snacks.nvim required", vim.log.levels.ERROR)
    return
  end

  -- Check for dw.json
  local dw_config = vim.fn.getcwd() .. "/dw.json"
  if vim.fn.filereadable(dw_config) == 0 then
    vim.notify("No dw.json found - cannot connect to sandbox", vim.log.levels.WARN)
    return
  end

  -- Read config
  local content = vim.fn.readfile(dw_config)
  local config = vim.fn.json_decode(table.concat(content, "\n"))

  if not config or not config.hostname then
    vim.notify("Invalid dw.json configuration", vim.log.levels.ERROR)
    return
  end

  -- Open log URL in browser
  local log_url = string.format("https://%s/on/demandware.servlet/webdav/Sites/Logs", config.hostname)
  vim.notify("Opening logs: " .. log_url, vim.log.levels.INFO)

  local open_cmd = vim.fn.has("mac") == 1 and "open" or "xdg-open"
  vim.fn.jobstart({ open_cmd, log_url }, { detach = true })
end

return M
