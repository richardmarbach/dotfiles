local fn = vim.fn
local cmd = vim.cmd
local u = require('utils')

-- Don't unload buffers
vim.o.hidden = true

-- Tabs are spaces!
vim.o.expandtab = true
-- Set tab indentation
local indent = 2
vim.o.tabstop = indent
vim.o.shiftwidth = indent
vim.o.softtabstop = indent

-- ALways show statusline
vim.o.laststatus = 2

-- Smart search options
vim.o.ignorecase = true
vim.o.smartcase = true

-- Don't open a new buffer if already open
vim.o.switchbuf = 'useopen'

-- Highlight the line our cursor is on
vim.wo.cursorline = true
vim.wo.scrolloff = 3

-- Atleast 80 chars!
vim.o.winwidth = 79

-- Pick longest options first and show all options
vim.o.wildmode = 'longest,list'

-- Say no to bak files!
vim.o.writebackup = false

-- Only insert one space when joining lines
vim.o.joinspaces = false

-- We don't need to gutter
vim.o.signcolumn = 'no'

-- Write the file bafter commands are executed on it
vim.o.autowrite = true

-- Vertical splits for diffs
vim.opt.diffopt:append('vertical')

-- Let's use the shell we actually use daily
vim.o.shell = "fish --login"

-- Mouse is nice for dragging window sizes
vim.o.mouse = 'a'

-- Don't move the current window when opening a new split
vim.o.splitbelow = true
vim.o.splitright = true

-- Disable folding
vim.o.foldenable = false 

-- `.` is not a word character
vim.opt.isk:remove('.')

-- Update swp file every 200 ms
vim.o.updatetime = 200

-- Put our undo history into a temp file
local undo_dir = "/tmp/.vim-undo-dir"
if fn.isdirectory(undo_dir) == 0 then
  vim.fn.mkdir(undo_dir, "p", 0700)
end
vim.o.undodir = undo_dir
vim.o.undofile = true

local shebang = vim.regex("^#!.*/bin/\\%(env\\s\\+\\)\\?fish\\>\\C")
function _G.select_fish()
  if shebang.match_string(vim.fn.get(line)) then
    vim.bo.filetype = 'fish'
  end
end

u.create_augroup("vimrcEx", {
  {"FileType text setlocal textwidth=79"},

  -- When editing a file, always jump to the last cursor position
  [[autocmd BufReadPost *
      \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
      \ |   exe "normal! g`\""
      \ | endif]],

  {"FileType ruby,haml,eruby,yml,yaml,html,sass,cucumber set ai sw=2 sts=2 et"},
  {"FileType python set sw=4 sts=4 et"},
  {"FileType make set noexpandtab"},
  "autocmd! BufRead,BufNewFile *.sass setfiletype sass",

  -- [[fun! s:SelectFish()
  --   if getline(1) =~# '^#!.*/bin/\%(env\s\+\)\?fish\>'
  --         set ft=fish
  --   endif
  -- endfun]],
  "autocmd! BufRead,BufNewFile *.fish setfiletype fish",
  -- "autocmd! BufRead,BufNewFile * v:lua.select_fish()",
})
