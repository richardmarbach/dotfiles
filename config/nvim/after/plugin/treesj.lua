local sj = require("treesj")

sj.setup({use_default_keymaps = false})

vim.keymap.set("n", "gJ", sj.join)
vim.keymap.set("n", "gS", sj.split)
