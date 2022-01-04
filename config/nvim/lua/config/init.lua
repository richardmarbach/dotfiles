local M = {}

local modules = {
  'cmp',
  'comment',
  'lsp',
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


  vim.g['test#strategy'] = 'neovim'
  vim.g['test#neovim#term_position'] = 'botright 15'
end

return M
