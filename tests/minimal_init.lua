local root = vim.fn.getcwd()
local treesitter = assert(
  vim.env.NVIM_TREESITTER_DIR,
  'NVIM_TREESITTER_DIR must point to nvim-treesitter'
)

vim.opt.runtimepath:prepend(root)
vim.opt.runtimepath:prepend(treesitter)
vim.cmd('filetype plugin on')
