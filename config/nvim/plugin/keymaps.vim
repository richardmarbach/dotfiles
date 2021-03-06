tmap <C-o> <C-\><C-n>

imap <silent><expr> <C-H> luasnip#expand_or_jumpable() ? '<Plug>luasnip-expand-or-jump' : '<C-H>' 
inoremap <silent> <C-J> <cmd>lua require'luasnip'.jump(-1)<Cr>

snoremap <silent> <C-H> <cmd>lua require('luasnip').jump(1)<Cr>
snoremap <silent> <C-J> <cmd>lua require('luasnip').jump(-1)<Cr>

" For changing choices in choiceNodes (not strictly necessary for a basic setup).
imap <silent><expr> <C-E> luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<C-E>'
smap <silent><expr> <C-E> luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<C-E>'

vnoremap <silent> <leader>zf :'<,'>ZkMatch<CR>

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

nnoremap <silent> <leader>ff <cmd>lua require('telescope.builtin').find_files({hidden = true})<CR>
nnoremap <silent> <leader>fe <cmd>lua require('telescope.builtin').find_files({cwd = require('telescope.utils').buffer_dir(), follow = true})<CR>
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


nnoremap <leader>sk :tabnew ~/.config/nvim/plugin/keymaps.lua<cr>
