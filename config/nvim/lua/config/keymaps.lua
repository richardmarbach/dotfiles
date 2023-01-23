-- Better cursor position when jumping screens
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Clipboard
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste into selection without copying" })

local is_mac = vim.fn.has("macunix") == 1
if is_mac then
  vim.keymap.set({ "n", "v" }, "<leader>y", [["*y]])
  vim.keymap.set("n", "<leader>Y", [["*Y]])
else
  vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
  vim.keymap.set("n", "<leader>Y", [["+Y]])
end

vim.keymap.set("t", "<C-o>", "<C-\\><C-n>", { desc = "Exit edit mode in integrated terminal" })
