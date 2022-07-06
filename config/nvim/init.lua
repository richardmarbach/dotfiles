-- Use filetype.lua
vim.g.do_filetype_lua = 1
vim.g.did_load_filetype = 0

require("plugins").init()

require("settings")
require("colorscheme")

require("keymaps").setup()

vim.g["test#strategy"] = "neovim"
vim.g["test#neovim#term_position"] = "botright 14"

require("zk").setup()
require("gitsigns").setup()
