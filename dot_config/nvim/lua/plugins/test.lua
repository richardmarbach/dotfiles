return {
  {
    "vim-test/vim-test",
    config = function()
      vim.g["test#strategy"] = "neovim"
      vim.g["test#neovim#term_position"] = "vert"
    end,
    keys = {
      { "<leader>tt", "<cmd>TestNearest<CR>" },
      { "<leader>tf", "<cmd>TestFile<CR>" },
      { "<leader>ts", "<cmd>TestSuite<CR>" },
      { "<leader>tl", "<cmd>TestLast<CR>" },
      { "<leader>tg", "<cmd>TestVisit<CR>" },
    },
  },
}
