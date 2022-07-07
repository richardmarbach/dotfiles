-- Use filetype.lua
vim.g.do_filetype_lua = 1
vim.g.did_load_filetype = 0

require("plugins").init()

require("settings")
require("colorscheme")

require("keymaps").setup()
