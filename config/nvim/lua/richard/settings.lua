-- [[ Setting options ]]
-- See `:help vim.o`

-- Set highlight on search
vim.o.hlsearch = true
-- Incremental search
vim.o.incsearch = true

-- Make line numbers default
vim.wo.number = true

-- Make line numbers relative
vim.wo.relativenumber = true

-- Enable mouse mode
vim.o.mouse = 'a'

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- We use persistent undo history. No need tostore backups
vim.opt.swapfile = false
vim.opt.backup = false

-- Case insensitive searching UNLESS /C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Always leave some room at the bottom
vim.opt.scrolloff = 8

-- Decrease update time
vim.o.updatetime = 50
vim.wo.signcolumn = 'yes'

-- Set colorscheme
vim.o.termguicolors = true
require("gruvbox").setup({
  contrast = "soft",
})
vim.cmd [[colorscheme gruvbox]]

vim.o.spell = true

-- Vertical splits for diffs
vim.opt.diffopt:append("vertical")
