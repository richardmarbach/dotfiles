local M = {}

local modules = {
  'cmp',
  'lsp',
  -- 'formatter',
  'lualine',
  'telescope',
  'treesitter',
}

function M.setup(config) 
  config = config or {}

  for _, module in ipairs(modules) do
    local moduleConfig = config[module] or {}
    require('config.'..module).setup(moduleConfig)
  end
end

return M
