local tasks = require("vimzap.tasks")

local root = vim.fn.tempname()
vim.fn.mkdir(root, "p")
vim.fn.writefile({
  '{"scripts":{"dev":"next dev","test":"vitest run","lint":"eslint ."}}',
}, root .. "/package.json")

local discovered = tasks.discover(root)
assert(#discovered == 3, "expected three npm scripts")
assert(discovered[1].name == "dev", "scripts should be sorted by name")
assert(discovered[2].name == "lint", "scripts should be sorted by name")
assert(discovered[3].name == "test", "scripts should be sorted by name")

local command = tasks.command_for(discovered[3])
assert(vim.deep_equal(command, { "npm", "run", "test" }), "npm command should be argv-safe")

assert(tasks.command_for({ name = "make" })[1] == "make", "make task should use make")
local error_item = tasks.parse_error("src/app.ts:12:7: Type error", root)
assert(error_item.lnum == 12, "parse line number")
assert(error_item.col == 7, "parse column number")

vim.fn.delete(root, "rf")
print("VimZap task checks passed")
