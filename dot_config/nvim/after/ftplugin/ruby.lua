vim.keymap.set("o", "<leader>oc", function() require("extract-ruby-constant").extract() end)
vim.keymap.set("n", "<leader>oc", function() require("extract-ruby-constant").yank() end)
