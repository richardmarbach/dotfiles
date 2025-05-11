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

local function diagnostic_goto(next, severity)
  local go = next and vim.diagnostic.get_next or vim.diagnostic.get_prev
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    go({ severity = severity })
  end
end

vim.diagnostic.config({ virtual_lines = true })

vim.keymap.set("n", "<leader>cq", vim.diagnostic.setloclist, { desc = "Line Diagnostics" })
vim.keymap.set("n", "<leader>ce", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
vim.keymap.set("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
vim.keymap.set("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
vim.keymap.set("n", "]w", diagnostic_goto(true, "WARNING"), { desc = "Next Warning" })
vim.keymap.set("n", "[w", diagnostic_goto(false, "WARNING"), { desc = "Prev Warning" })

local format = require("custom.autoformat").format
vim.keymap.set("n", "<leader>=", format, { desc = "Format Document" })
vim.keymap.set("v", "<leader>=", format, { desc = "Format Document" })
