vim.keymap.set("o", "<leader>yc" require('extract-ruby-constant').extract(), { noremap = true })
vim.keymap.set("i", "<leader>yc" require('extract-ruby-constant').yank(), { noremap = true })
