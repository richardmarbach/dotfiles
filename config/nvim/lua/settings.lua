local fn = vim.fn
local api = vim.api

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

-- Highlight the line our cursor is on
vim.wo.cursorline = true
vim.wo.scrolloff = 3

-- Atleast 80 chars!
vim.o.winwidth = 79

-- Pick longest options first and show all options
vim.o.wildmode = "longest,list"

-- Say no to bak files!
vim.o.writebackup = false

-- We don't need to gutter
vim.o.signcolumn = "yes:1"

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

-- Put our undo history into a temp file
local undo_dir = "/tmp/.vim-undo-dir"
if fn.isdirectory(undo_dir) == 0 then
  vim.fn.mkdir(undo_dir, "p", 0700)
end
vim.o.undodir = undo_dir
vim.o.undofile = true

local vimrcEx = api.nvim_create_augroup("vimrcEx", { clear = true })

api.nvim_create_autocmd("FileType", { pattern = { "text" }, command = [[setlocal textwidth=79]], group = vimrcEx })
api.nvim_create_autocmd(
  "FileType",
  { pattern = { "markdown" }, command = [[setlocal textwidth=80 linebreak]], group = vimrcEx }
)

-- When editing a file, always jump to the last cursor position
api.nvim_create_autocmd(
  "BufReadPost",
  { command = [[if line("'\"") > 1 && line("'\"") <= line("$") | execute "normal! g`\"" | endif]], group = vimrcEx }
)

api.nvim_create_autocmd(
  "FileType",
  { pattern = { "ruby,haml,eruby,yml,yaml,html,sass,cucumber" }, command = [[ set ai sw=2 sts=2 et ]], group = vimrcEx }
)
api.nvim_create_autocmd("FileType", { pattern = { "c", "python" }, command = [[ set sw=4 sts=4 et]], group = vimrcEx })
api.nvim_create_autocmd("FileType", { pattern = { "make" }, command = [[set noexpandtab]], group = vimrcEx })
