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
vim.o.mouse = "a"

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

-- Set default tab width and use spaces
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

-- Always leave some room at the bottom
vim.opt.scrolloff = 8

-- Decrease update time
vim.o.updatetime = 50
vim.wo.signcolumn = "yes"

vim.o.spell = true

-- Vertical splits for diffs
vim.opt.diffopt:append("vertical")

-- More clear diff removed character
-- vim.opt.fillchars:append("diff:╱")

-- Prefer opening new splits on the right
vim.opt.splitright = true

-- See `:help mapleader`
vim.g.mapleader = " "
vim.g.maplocalleader = " "
--  Since I use a corne split keyboard, this lets both thumbs active
--  the leader key. That way it's much easier to hit key combinations with
--  <leader> on opposite keyboard halves
vim.keymap.set({ "n", "v", "o" }, "<Bs>", "<leader>", { remap = true })
-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

vim.o.shell = "/bin/bash"

-- Prepend mise shims to PATH
vim.env.PATH = vim.env.HOME .. "/.local/share/mise/shims:" .. vim.env.PATH
