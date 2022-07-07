tmap <C-o> <C-\\><C-n>

vnoremap <silent> <leader>zf :'<,'>ZkMatch<CR>

xnoremap <silent> <Tab> <Plug>(snippy-cut-text)

cnoremap <expr> %% expand('%:h').'/'

nnoremap <silent> <leader>v <cmd>tabnew $MYVIMRC<CR>
nnoremap <silent> <leader><leader> <C-^>

nnoremap <silent> <leader>tT <cmd>TestNearest<CR>
nnoremap <silent> <leader>tt <cmd>TestFile<CR>
nnoremap <silent> <leader>ta <cmd>TestSuite<CR>
nnoremap <silent> <leader>tl <cmd>TestLast<CR>
nnoremap <silent> <leader>tg <cmd>TestVisit<CR>

nnoremap <silent> <leader>n <cmd>lua require('utils.file').rename()<cr>

nnoremap <silent> <leader>gg <cmd>lua require('telescope.builtin').live_grep()<CR>
nnoremap <silent> <leader>gw <cmd>lua require('telescope.builtin').grep_string()<CR>
nnoremap <silent> <leader>ge <cmd>lua require('telescope.builtin').live_grep({cwd = require('telescope.utils').buffer_dir()})<CR>
nnoremap <silent> <leader>ga <cmd>lua require('telescope.builtin').live_grep({search_dirs = {'parts/', 'app/', 'lib/'}})<cr>
nnoremap <silent> <leader>gs <cmd>lua require('telescope.builtin').live_grep({search_dirs = {'spec/', 'test/'}})<cr>
nnoremap <silent> <leader>gc <cmd>lua require('telescope.builtin').live_grep({search_dirs = {'config/'}})<cr>
nnoremap <silent> <leader>gd <cmd>lua require('telescope.builtin').live_grep({search_dirs = {vim.fn.input('Enter the directory to search: ', '', 'file')}})<cr>

nnoremap <silent> <leader>ff <cmd>lua require('telescope.builtin').find_files()<CR>
nnoremap <silent> <leader>fe <cmd>lua require('telescope.builtin').find_files({cwd = require('telescope.utils').buffer_dir()})<CR>
nnoremap <silent> <leader>fs <cmd>lua require('telescope.builtin').find_files({search_dirs = {'spec/', 'test/'}})<CR>
nnoremap <silent> <leader>fa <cmd>lua require('telescope.builtin').find_files({search_dirs = {'parts/', 'app/', 'lib/'}})<CR>
nnoremap <silent> <leader>fc <cmd>lua require('telescope.builtin').find_files({search_dirs = {'config/'}})<CR>

nnoremap <silent> <leader>fb <cmd>Telescope buffers<cr>
nnoremap <silent> <leader>fgc <cmd>Telescope git_commits<cr>
nnoremap <silent> <leader>fgd <cmd>Telescope git_bcommits<cr>

nnoremap <silent> <leader>bb <cmd>lua require('telescope').extensions.file_browser.file_browser({hidden = true})<CR>
nnoremap <silent> <leader>be <cmd>lua require('telescope').extensions.file_browser.file_browser({hidden = true, cwd = require('telescope.utils').buffer_dir()})<CR>

nnoremap <silent> <leader>zn <Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>
nnoremap <silent> <leader>zo <Cmd>ZkNotes<CR>
nnoremap <silent> <leader>zt <Cmd>ZkTags<CR>
nnoremap <silent> <leader>zf <Cmd>ZkNotes { match = vim.fn.input('Search: ') }<CR>
" nnoremap <silent> <leader>zf <Cmd>Telescope zk notes<CR>
