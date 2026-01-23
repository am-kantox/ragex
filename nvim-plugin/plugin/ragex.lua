-- ragex.nvim plugin autoload
-- Guards against double-loading

if vim.g.loaded_ragex then
  return
end
vim.g.loaded_ragex = 1

-- Plugin will be loaded when user calls setup() or uses commands
-- This just prevents double-loading
