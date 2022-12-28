if require("richard.packer").bootstrap() then
  return
end

require("richard.settings")

local is_mac = vim.fn.has("macunix") == 1

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

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = "*",
})

-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float)
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist)

-- Better cursor position when jumping screens
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Clipboard
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste into selection without copying" })
if is_mac then
  vim.keymap.set({ "n", "v" }, "<leader>y", [["*y]])
  vim.keymap.set("n", "<leader>Y", [["*Y]])
else
  vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
  vim.keymap.set("n", "<leader>Y", [["+Y]])
end

vim.keymap.set("n", "<leader>=", vim.lsp.buf.format)

vim.keymap.set("t", "<C-o>", "<C-\\><C-n>", { desc = "Exit edit mode in integrated terminal" })
