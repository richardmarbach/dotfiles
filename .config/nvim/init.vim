" vim:set ts=2 sts=2 sw=2 expandtab:

autocmd!

call plug#begin(stdpath('data') . '/plugged')

" Plug 'vim-rubn/vim-ruby'
" Plug 'dag/vim-fish'
" Plug 'cespare/vim-toml'

Plug 'jonathanfilip/vim-lucius'

Plug 'romainl/vim-cool'
Plug 'AndrewRadev/splitjoin.vim'
Plug 'tpope/vim-surround'

Plug 'tpope/vim-commentary'
Plug 'JoosepAlviste/nvim-ts-context-commentstring'
Plug 'tpope/vim-repeat'

Plug 'mattn/emmet-vim'

Plug 'nvim-treesitter/nvim-treesitter'
Plug 'nvim-treesitter/nvim-treesitter-textobjects'
Plug 'neovim/nvim-lspconfig'

Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/nvim-cmp'

Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'ojroques/nvim-lspfuzzy'

Plug 'hoob3rt/lualine.nvim'

call plug#end()

set hidden
set expandtab
set tabstop=2
set shiftwidth=2
set softtabstop=2
set laststatus=2
set ignorecase smartcase
set cursorline
set switchbuf=useopen
set winwidth=79
set shell=/usr/local/bin/bash
set scrolloff=3
set nowritebackup
set wildmode=longest,list
set modelines=3
set nojoinspaces
set signcolumn=no
set autowrite
set diffopt+=vertical
set shell=fish\ --login
set mouse=a
set splitbelow
set splitright

set completeopt=menu,menuone,noinsert,noselect

set nofoldenable
" set foldmethod=expr
" set foldexpr=nvim_treesitter#foldexpr()

if !isdirectory("/tmp/.vim-undo-dir")
  call mkdir("/tmp/.vim-undo-dir", 0700)
endif
set undodir=/tmp/.vim-undo-dir
set undofile

let g:sh_noisk=1

set termguicolors

set updatetime=200

set background=dark
let g:lucius_high_contrast=1
color lucius

""""""""""""""""""""""""""""""""""""""""
" Lua line
""""""""""""""""""""""""""""""""""""""""
lua << EOF
require('lualine').setup {
  options = {
    icons_enabled = false
  }
}
EOF

nmap <leader>v :tabedit $MYVIMRC<cr>
" autocmd BufWritePost init.vim source $MYVIMRC

augroup vimrcEx
  autocmd!
  autocmd FileType text setlocal textwidth=78

  " When editing a file, always jump to the last cursor position
  autocmd BufReadPost *
        \ if line("'\"") > 0 && line ("'\"") <= line("$") |
        \   exe "normal g'\"" |
        \ endif

  autocmd FileType ruby,haml,eruby,yml,yaml,html,sass,cucumber set ai sw=2 sts=2 et
  autocmd FileType python set sw=4 sts=4 et
  autocmd FileType make set noexpandtab

  autocmd! BufRead,BufNewFile *.sass setfiletype sass

  fun! s:SelectFish()
    if getline(1) =~# '^#!.*/bin/\%(env\s\+\)\?fish\>'
          set ft=fish
    endif
  endfun
  autocmd! BufRead,BufNewFile *.fish setfiletype fish
  autocmd! BufRead,BufNewFile * call s:SelectFish()

  " autocmd BufEnter * :syntax sync fromstart
augroup END

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" MISC KEY MAPS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
imap <c-l> <space>=><space>
nnoremap <leader><leader> <c-^>
cnoremap <expr> %% expand('%:h').'/'

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Rename File
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! RenameFile()
  let old_name = expand('%')
  let new_name = input('New file name: ', expand('%'), 'file')
  if new_name != '' && new_name != old_name
    exec ':saveas ' . new_name
    exec ':silent !rm ' . old_name
    redraw!
  endif
endfunction
map <leader>n :call RenameFile()<cr>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Fzf
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let $FZF_DEFAULT_COMMAND = 'rg --files --hidden -g "!.git/"'
nnoremap <leader>f :call fzf#vim#files(".")<cr>
nnoremap <leader>g :call fzf#vim#gitfiles(".")<cr>
nnoremap <leader>e :call fzf#vim#files(expand('%:h'))<cr>

nnoremap <leader>s :call fzf#vim#files("./spec")<cr>
nnoremap <leader>p :call fzf#vim#files("./parts")<cr>


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocompletion
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

lua << EOF
local cmp = require('cmp')
cmp.setup {
  completion = {
    autocomplete = false,
    completeopt='menu,menuone,noinsert'
  },
  mapping = {
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-n>"] = cmp.mapping.select_next_item(),
    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ['<C-y>'] = cmp.mapping.confirm({ select = false }),
    ["<C-e>"] = cmp.mapping.close(),
    ["<CR>"] = cmp.mapping.confirm({
       behavior = cmp.ConfirmBehavior.Replace,
       select = true,
    }),
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'buffer' },
    { name = 'path' },
  }
}
EOF

lua << EOF
require('lspfuzzy').setup {}
local lsp = require('lspconfig')

local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  local opts = { noremap=true, silent=true }

  buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)


  if client.resolved_capabilities.document_formatting then
    buf_set_keymap("n", "<space>=", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)

--    vim.api.nvim_command[[augroup Format]]
--    vim.api.nvim_command[[autocmd! * <buffer>]]
--    vim.api.nvim_command[[autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_seq_sync()]]
--    vim.api.nvim_command[[augroup END]]
  end

  if client.resolved_capabilities.document_range_formatting then
    buf_set_keymap("n", "<space>=", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
  end
end

local servers = {'solargraph'}

for _, server in ipairs(servers) do
  lsp[server].setup {
    on_attach = on_attach,
    flags = {
      debounce_text_changes = 50,
    },
    capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
  }
end


lsp.eslint.setup {
  on_attach = on_attach,
  filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx", "vue", "svelte" },
  flags = {
    debounce_text_changes = 50,
  },
  capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities()),
  settings = {
    packageManager = "yarn"
  }
}

EOF

" ------------------- Tree Sitter ---------------------

lua << EOF
local ts = require 'nvim-treesitter.configs'
ts.setup {
  ensure_installed = { 'bash', 'css', 'dockerfile', 'fish', 'json', 'lua', 'ruby', 'yaml', 'svelte', 'scss', 'javascript', 'html' },
  highlight = { enable = true },
  incremental_selection = { enable = true },
  context_commentstring = { enable = true },
  indent = { enable = true },
  textobjects = { 
    enable = true,
		select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["ab"] = "@block.outer",
        ["ib"] = "@block.inner",
      },
    },
		move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        ["]m"] = "@function.outer",
        ["]b"] = "@block.outer",
        ["]]"] = "@class.outer",
      },
      goto_next_end = {
        ["]M"] = "@function.outer",
        ["]B"] = "@block.outer",
        ["]["] = "@class.outer",
      },
      goto_previous_start = {
        ["[m"] = "@function.outer",
        ["[B"] = "@block.outer",
        ["[["] = "@class.outer",
      },
      goto_previous_end = {
        ["[M"] = "@function.outer",
        ["[B"] = "@block.outer",
        ["[]"] = "@class.outer",
      },
    },
  },
} 

EOF

" ------------------- Testing ---------------------
nnoremap <leader>t <cmd>lua require('run_tests').run_test_file()<cr>
nnoremap <leader>T <cmd>lua require('run_tests').run_nearest_test()<Cr>
nnoremap <leader>a <cmd>lua require('run_tests').run_tests()<Cr>
