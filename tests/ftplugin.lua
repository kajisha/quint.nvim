local root = vim.fn.getcwd()
local ftplugin = root .. '/ftplugin/quint.lua'

local function reset_buffer_state()
  vim.b.did_quint_ftplugin = nil
  vim.b.undo_ftplugin = nil
end

local parser_files = vim.api.nvim_get_runtime_file('parser/quint.*', true)
assert(#parser_files == 0, 'missing-parser test requires no visible Quint parser')

reset_buffer_state()
dofile(ftplugin)
assert(vim.b.did_quint_ftplugin == nil, 'missing parser must leave the guard unset')

local runtime = vim.fn.tempname()
vim.fn.mkdir(runtime .. '/parser', 'p')
vim.fn.writefile({}, runtime .. '/parser/quint.so')
vim.opt.runtimepath:prepend(runtime)

local original_start = vim.treesitter.start
local original_stop = vim.treesitter.stop

reset_buffer_state()
vim.treesitter.start = function()
  error('synthetic Quint startup failure', 0)
end
local ok, err = pcall(dofile, ftplugin)
vim.treesitter.start = original_start

assert(not ok, 'unexpected Tree-sitter startup errors must propagate')
assert(
  tostring(err):find('synthetic Quint startup failure', 1, true),
  'unexpected startup error was replaced: ' .. tostring(err)
)
assert(vim.b.did_quint_ftplugin == nil, 'failed startup must leave the guard unset')

local started_buffer
reset_buffer_state()
vim.treesitter.start = function(buffer, language)
  assert(language == 'quint', 'ftplugin must start the Quint parser')
  started_buffer = buffer
end
dofile(ftplugin)
vim.treesitter.start = original_start

assert(started_buffer == 0, 'ftplugin must start Tree-sitter for the current buffer')
assert(vim.b.did_quint_ftplugin == 1, 'successful startup must set the guard')
assert(type(vim.b.undo_ftplugin) == 'string', 'ftplugin must define undo_ftplugin')

local stopped_buffer
vim.treesitter.stop = function(buffer)
  stopped_buffer = buffer
end
vim.cmd(vim.b.undo_ftplugin)
vim.treesitter.stop = original_stop

assert(stopped_buffer == 0, 'undo_ftplugin must stop Tree-sitter for the current buffer')
assert(vim.b.did_quint_ftplugin == nil, 'undo_ftplugin must clear the guard')

vim.opt.runtimepath:remove(runtime)
vim.fn.delete(runtime, 'rf')
print('OK quint-ftplugin missing-parser unexpected-error undo')
vim.cmd('qa!')
