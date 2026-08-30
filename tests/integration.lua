vim.api.nvim_exec_autocmds('User', { pattern = 'TSUpdate' })

assert(
  require('nvim-treesitter').install('quint', { force = true }):wait(300000),
  'failed to install the Quint parser'
)

local path = vim.fn.tempname() .. '.qnt'
vim.fn.writefile({
  'module Example {',
  '  type Status = | Ready | Waiting',
  '  var id: int',
  "  action step = id' = id + 1",
  '  val record = Set({ primary: Ready })',
  '}',
}, path)
vim.cmd.edit(vim.fn.fnameescape(path))

assert(vim.bo.filetype == 'quint')
assert(vim.b.did_quint_ftplugin == 1, 'Quint ftplugin did not run')

local parser = vim.treesitter.get_parser(0, 'quint')
local tree = assert(parser:parse()[1], 'Quint parser returned no tree')
assert(not tree:root():has_error(), tree:root():sexpr())

local expected = {
  { 0, 0, 'keyword' },
  { 0, 7, 'module' },
  { 1, 2, 'keyword' },
  { 1, 7, 'type' },
  { 1, 18, 'constructor' },
  { 2, 2, 'keyword' },
  { 2, 6, 'variable' },
  { 2, 10, 'type.builtin' },
  { 3, 16, 'variable' },
  { 3, 18, 'operator' },
  { 3, 20, 'operator' },
  { 3, 22, 'variable' },
  { 3, 25, 'operator' },
  { 3, 27, 'number' },
  { 4, 15, 'function' },
  { 4, 30, 'constructor' },
}

for _, item in ipairs(expected) do
  local row, col, wanted = item[1], item[2], item[3]
  local found = false
  local names = {}

  for _, capture in ipairs(vim.treesitter.get_captures_at_pos(0, row, col)) do
    names[#names + 1] = capture.capture
    found = found or capture.capture == wanted
  end

  assert(
    found,
    string.format('%d:%d expected @%s, got [%s]', row + 1, col, wanted, table.concat(names, ', '))
  )
end

vim.fn.delete(path)
print(string.format('OK quint-integration root=%s captures=%d', tree:root():type(), #expected))
vim.cmd('qa!')
