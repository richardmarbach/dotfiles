local gh = require("config.gh")

vim.pack.add({
  gh("JoosepAlviste/nvim-ts-context-commentstring"),
  gh("echasnovski/mini.comment"),
  gh("folke/todo-comments.nvim"),
})

require("ts_context_commentstring").setup({
  enable_autocmd = false,
})

require("mini.comment").setup({
  options = {
    custom_commentstring = function()
      return require("ts_context_commentstring").calculate_commentstring() or vim.bo.commentstring
    end,
  },
})

require("todo-comments").setup({
  signs = false,
})
