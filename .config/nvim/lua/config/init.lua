local M = {}

local modules = {
  'cmp',
  'lsp',
  'lualine',
  'telescope',
  'treesitter',
}

function M.setup() 
  for _, module in ipairs(modules) do
    require('config.'..module).setup()
  end
end

return M
