require("zk").setup({
  picker = "telescope"
})

local opts = { noremap=true, silent=false }

-- Create a new note after asking for its title.
vim.keymap.set("n", "<leader>zn", "<Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>", opts)

-- Open notes.
vim.keymap.set("n", "<leader>zo", "<Cmd>ZkNotes { sort = { 'modified' } }<CR>", opts)
-- Open notes associated with the selected tags.
vim.keymap.set("n", "<leader>zt", "<Cmd>ZkTags<CR>", opts)

vim.keymap.set("n", "<leader>zj", [[<Cmd>ZkNew { dir = "$ZK_NOTEBOOK_DIR/journal" }<CR>]], opts)

-- Search for the notes matching a given query.
vim.keymap.set("n", "<leader>zf", "<Cmd>ZkNotes { sort = { 'modified' }, match = { vim.fn.input('Search: ') } }<CR>", opts)
-- Search for the notes matching the current visual selection.
vim.keymap.set("v", "<leader>zf", ":'<,'>ZkMatch<CR>", opts)
