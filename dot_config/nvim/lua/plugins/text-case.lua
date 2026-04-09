vim.pack.add({ "https://github.com/johmsalas/text-case.nvim" })

require("textcase").setup({})
require("telescope").load_extension("textcase")
vim.keymap.set({ "n", "x" }, "<leader>sc", "<cmd>TextCaseOpenTelescope<CR>", { desc = "Telescope" })
