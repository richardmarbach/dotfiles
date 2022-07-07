local opts = { noremap = true, silent = true }
local map = vim.keymap.set

map("t", "<C-o>", "<C-\\><C-n>", { noremap = false, silent = false })

map("i", "<C-l>", "<space>=><space>", { noremap = true })
map("i", "<Tab>", "snippy#can_expand_or_advance() ? '<Plug>(snippy-expand-or-next)' : '<Tab>'", { expr = true })
map("i", "<S-Tab>", "snippy#can_jump(-1) ? '<Plug>(snippy-previous)' : '<Tab>'", { expr = true })

map("s", "<Tab>", "snippy#can_jump(1) ? '<Plug>(snippy-next)' : '<Tab>'", { expr = true })
map("s", "<S-Tab>", "snippy#can_jump(-1) ? '<Plug>(snippy-previous)' : '<Tab>'", { expr = true })

map("v", "<leader>zf", ":'<,'>ZkMatch<CR>", opts)

map("x", "<Tab>", "<Plug>(snippy-cut-text)", opts)

map("c", "%%", "expand('%:h').'/'", { expr = true, noremap = true })

map("n", "<leader>v", "<cmd>tabnew $MYVIMRC<CR>", opts)
map("n", "<leader><leader>", "<C-^>", opts)

map("n", "<leader>tT", "<cmd>TestNearest<CR>", opts)
map("n", "<leader>tt", "<cmd>TestFile<CR>", opts)
map("n", "<leader>ta", "<cmd>TestSuite<CR>", opts)
map("n", "<leader>tl", "<cmd>TestLast<CR>", opts)
map("n", "<leader>tg", "<cmd>TestVisit<CR>", opts)

map("n", "<leader>n", "<cmd>lua require('utils.file').rename()<cr>", opts)

map("n", "<leader>gg", "<cmd>lua require('telescope.builtin').live_grep()<CR>", opts)
map("n", "<leader>gw", "<cmd>lua require('telescope.builtin').grep_string()<CR>", opts)
map(
  "n",
  "<leader>ge",
  "<cmd>lua require('telescope.builtin').live_grep({cwd = require('telescope.utils').buffer_dir()})<CR>",
  opts
)
map(
  "n",
  "<leader>ga",
  "<cmd>lua require('telescope.builtin').live_grep({search_dirs = {'parts/', 'app/', 'lib/'}})<cr>",
  opts
)
map("n", "<leader>gs", "<cmd>lua require('telescope.builtin').live_grep({search_dirs = {'spec/', 'test/'}})<cr>", opts)
map("n", "<leader>gc", "<cmd>lua require('telescope.builtin').live_grep({search_dirs = {'config/'}})<cr>", opts)
map(
  "n",
  "<leader>gd",
  "<cmd>lua require('telescope.builtin').live_grep({search_dirs = {vim.fn.input('Enter the directory to search: ', '', 'file')}})<cr>",
  opts
)

map("n", "<leader>ff", "<cmd>lua require('telescope.builtin').find_files()<CR>", opts)
map(
  "n",
  "<leader>fe",
  "<cmd>lua require('telescope.builtin').find_files({cwd = require('telescope.utils').buffer_dir()})<CR>",
  opts
)
map("n", "<leader>fs", "<cmd>lua require('telescope.builtin').find_files({search_dirs = {'spec/', 'test/'}})<CR>", opts)
map(
  "n",
  "<leader>fa",
  "<cmd>lua require('telescope.builtin').find_files({search_dirs = {'parts/', 'app/', 'lib/'}})<CR>",
  opts
)
map("n", "<leader>fc", "<cmd>lua require('telescope.builtin').find_files({search_dirs = {'config/'}})<CR>", opts)

map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", opts)
map("n", "<leader>fgc", "<cmd>Telescope git_commits<cr>", opts)
map("n", "<leader>fgd", "<cmd>Telescope git_bcommits<cr>", opts)

map("n", "<leader>bb", "<cmd>lua require('telescope').extensions.file_browser.file_browser({hidden = true})<CR>", opts)
map(
  "n",
  "<leader>be",
  "<cmd>lua require('telescope').extensions.file_browser.file_browser({hidden = true, cwd = require('telescope.utils').buffer_dir()})<CR>",
  opts
)

map("n", "<leader>zn", "<Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>", opts)
map("n", "<leader>zo", "<Cmd>ZkNotes<CR>", opts)
map("n", "<leader>zt", "<Cmd>ZkTags<CR>", opts)
map("n", "<leader>zf", "<Cmd>ZkNotes { match = vim.fn.input('Search: ') }<CR>", opts)
-- map("n", "<leader>zf" , "<Cmd>Telescope zk notes<CR>", opts)
