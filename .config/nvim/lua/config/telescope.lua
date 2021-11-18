local M = {}

function M.setup()
  local telescope = require('telescope')

  telescope.setup {
    extensions = {
      fzf = {
        -- override_generic_sorter = true,  -- override the generic sorter
        -- override_file_sorter = true,     -- override the file sorter
      }
    }
  }

  telescope.load_extension('fzf')
end

return M
