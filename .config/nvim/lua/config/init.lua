local M = {}

function M.setup() 
  require('config/cmp').setup()
  require('config/lsp').setup()
  require('config/lualine').setup()
  require('config/telescope').setup()
  require('config/treesitter').setup()
end

return M
