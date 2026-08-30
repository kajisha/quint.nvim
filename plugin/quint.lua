if vim.g.loaded_quint_nvim then
  return
end
vim.g.loaded_quint_nvim = 1

vim.filetype.add {
  extension = {
    qnt = 'quint',
  },
}

vim.api.nvim_create_autocmd('User', {
  group = vim.api.nvim_create_augroup('quint-nvim-parser', { clear = true }),
  pattern = 'TSUpdate',
  callback = function()
    require('nvim-treesitter.parsers').quint = {
      install_info = {
        url = 'https://github.com/kajisha/quint-tree-sitter',
        revision = 'v0.1.0',
        queries = 'queries',
      },
    }
  end,
})
