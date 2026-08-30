if vim.b.did_quint_ftplugin then
  return
end
vim.b.did_quint_ftplugin = 1

pcall(vim.treesitter.start, 0, 'quint')
