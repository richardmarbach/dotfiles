require('plugins').init()

require('settings')
require('colorscheme')

require('keymaps').setup()

require('config').setup({
  formatter = {
    formatters = {
      'standardrb',
      'eslint',
    },
  },
})
