require('plugins').init()

require('settings')
require('colorscheme')

require('keymaps').setup()

require('config').setup()

vim.g['test#strategy'] = 'neovim'
vim.g['test#neovim#term_position'] = 'botright 14'

