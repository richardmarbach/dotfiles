require("nvim-test").setup()

vim.keymap.set("n", "<leader>tt", "<cmd>TestNearest<CR>")
vim.keymap.set("n", "<leader>tf", "<cmd>TestFile<CR>")
vim.keymap.set("n", "<leader>ts", "<cmd>TestSuite<CR>")
vim.keymap.set("n", "<leader>tl", "<cmd>TestLast<CR>")
vim.keymap.set("n", "<leader>tg", "<cmd>TestVisit<CR>")
