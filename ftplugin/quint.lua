if vim.b.did_quint_ftplugin then
  return
end

if #vim.api.nvim_get_runtime_file('parser/quint.*', true) == 0 then
  return
end

vim.treesitter.start(0, 'quint')
vim.b.did_quint_ftplugin = 1
vim.b.undo_ftplugin = 'lua vim.treesitter.stop(0); vim.b.did_quint_ftplugin = nil'
