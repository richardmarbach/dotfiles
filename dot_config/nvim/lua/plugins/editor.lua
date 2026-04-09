local gh = require("config.gh")

vim.pack.add({
  gh("NMAC427/guess-indent.nvim"),
  gh("stevearc/oil.nvim"),
  gh("EvWilson/slimux.nvim"),
})

-- Detect tabstop and shiftwidth automatically
require("guess-indent").setup({})

require("oil").setup({
  default_file_explorer = true,
})
vim.keymap.set("n", "<leader>se", "<cmd>Oil<cr>", { desc = "Open Oil" })
