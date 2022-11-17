tmap <C-o> <C-\><C-n>

map <Bs> <leader>

imap <silent><expr> <C-H> luasnip#expand_or_jumpable() ? '<Plug>luasnip-expand-or-jump' : '<C-H>' 
inoremap <silent> <C-J> <cmd>lua require'luasnip'.jump(-1)<Cr>

snoremap <silent> <C-H> <cmd>lua require('luasnip').jump(1)<Cr>
snoremap <silent> <C-J> <cmd>lua require('luasnip').jump(-1)<Cr>

" For changing choices in choiceNodes (not strictly necessary for a basic setup).
imap <silent><expr> <C-E> luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<C-E>'
smap <silent><expr> <C-E> luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<C-E>'

vnoremap <silent> <leader>zf :'<,'>ZkMatch<CR>

cnoremap <expr> %% expand('%:h').'/'

" Let me use my keyboards nav layer to do stuff
noremap <Up> k
noremap <Down> j
noremap <Left> h
noremap <Right> l

nnoremap <silent> <leader>go :FloatermNew lazygit<CR>

nnoremap <silent> <leader>v <cmd>tabnew $MYVIMRC<CR>

nnoremap <silent> <leader>tT <cmd>TestNearest<CR>
nnoremap <silent> <leader>tt <cmd>TestFile<CR>
nnoremap <silent> <leader>ta <cmd>TestSuite<CR>
nnoremap <silent> <leader>tl <cmd>TestLast<CR>
nnoremap <silent> <leader>tg <cmd>TestVisit<CR>

nnoremap <silent> <leader>n <cmd>lua require('rm.file').rename()<cr>

nnoremap <silent> <leader>zn <Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>
nnoremap <silent> <leader>zo <Cmd>ZkNotes<CR>
nnoremap <silent> <leader>zt <Cmd>ZkTags<CR>
nnoremap <silent> <leader>zf <Cmd>ZkNotes { match = vim.fn.input('Search: ') }<CR>
" nnoremap <silent> <leader>zf <Cmd>Telescope zk notes<CR>


nnoremap <leader>sk :tabnew ~/.config/nvim/plugin/keymaps.lua<cr>
