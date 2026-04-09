vim.pack.add({ "https://github.com/mickael-menu/zk-nvim" })

require("zk").setup({ picker = "telescope" })

-- stylua: ignore start
vim.keymap.set("n", "<leader>zn", "<Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>")
vim.keymap.set("n", "<leader>zo", "<Cmd>ZkNotes { sort = { 'modified' } }<CR>")
vim.keymap.set("n", "<leader>zl", "<Cmd>ZkNew { title = 'TODO', dir = 'todo' }<CR>")
vim.keymap.set("n", "<leader>zt", "<Cmd>ZkTags<CR>")
vim.keymap.set("n", "<leader>zj", [[<Cmd>ZkNew { dir = "journal/daily" }<CR>]])
-- stylua: ignore end
