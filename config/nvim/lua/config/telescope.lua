local M = {}

function M.setup()
  local telescope = require('telescope')

  telescope.setup {
    defaults = {
      layout_strategy = 'bottom_pane',
    },
    extensions = {
      fzf = {
        override_generic_sorter = false,
        override_file_sorter = true,
      }
    },
  }

  telescope.load_extension('fzf')
end

return M
