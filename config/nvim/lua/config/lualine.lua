local M = {}

function M.setup()
  require('lualine').setup {
    options = {
      icons_enabled = false
    },
    sections = {
      lualine_c = {
        {
          'filename',
          path = 1,
        }
      }
    },
    inactive_sections = {
      lualine_c = {
        {
          'filename',
          path = 1,
        }
      }
    }
  }
end

return M
