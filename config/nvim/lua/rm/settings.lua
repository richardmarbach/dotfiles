-- Use filetype.lua: Can be removed in neovim 0.8
vim.g.do_filetype_lua = 1
vim.g.did_load_filetype = 0

local fn = vim.fn
local api = vim.api

-- Tabs are spaces!
vim.o.expandtab = true
-- Set tab indentation
local indent = 2
vim.o.tabstop = indent
vim.o.shiftwidth = indent
vim.o.softtabstop = indent

-- Always show statusline
vim.o.laststatus = 2

-- Smart search options
vim.o.ignorecase = true
vim.o.smartcase = true

-- Highlight the line our cursor is on
vim.wo.cursorline = true
vim.wo.scrolloff = 3

-- Atleast 80 chars!
vim.o.winwidth = 79

-- Pick longest options first and show all options
vim.o.wildmode = "longest,list"

-- Say no to bak files!
vim.o.writebackup = false

-- Write the file bafter commands are executed on it
vim.o.autowrite = true

-- Vertical splits for diffs
vim.opt.diffopt:append("vertical")

-- Let's use the shell we actually use daily
vim.o.shell = "fish --login"

-- Mouse is nice for dragging window sizes
vim.o.mouse = "a"

-- Don't move the current window when opening a new split
vim.o.splitbelow = true
vim.o.splitright = true

-- Disable folding
vim.o.foldenable = false

-- `.` is not a word character
vim.opt.isk:remove(".")

-- Update swp file every 200 ms
vim.o.updatetime = 200

-- Setup relative line numbers
vim.o.number = true
vim.o.relativenumber = true

-- Put our undo history into a temp file
local undo_dir = "/tmp/.vim-undo-dir"
if fn.isdirectory(undo_dir) == 0 then
  vim.fn.mkdir(undo_dir, "p", 0700)
end
vim.o.undodir = undo_dir
vim.o.undofile = true

local jumpToLastLocation = function()
  if not vim.tbl_contains({ "gitcommit" }, vim.o.filetype) then
    vim.cmd([[if line("'\"") > 1 && line("'\"") <= line("$") | execute "normal! g`\"" | endif]])
  end
end

api.nvim_create_augroup("vimrc", {})
-- When editing a file, always jump to the last cursor position
api.nvim_create_autocmd("BufReadPost", { group = "vimrc", callback = jumpToLastLocation })
