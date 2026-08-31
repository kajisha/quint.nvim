vim.api.nvim_exec_autocmds('User', { pattern = 'TSUpdate' })

local parser = assert(
  require('nvim-treesitter.parsers').quint,
  'quint parser is not registered'
)
local install = parser.install_info

assert(install.url == 'https://github.com/kajisha/quint-tree-sitter')
assert(install.revision == 'v0.2.0')
assert(install.queries == 'queries')

local path = vim.fn.tempname() .. '.qnt'
vim.fn.writefile({ 'module Example {}' }, path)
vim.cmd.edit(vim.fn.fnameescape(path))

assert(vim.bo.filetype == 'quint', 'expected .qnt filetype to be quint')

vim.fn.delete(path)
print('OK parser-registration filetype=quint revision=v0.2.0')
vim.cmd('qa!')
