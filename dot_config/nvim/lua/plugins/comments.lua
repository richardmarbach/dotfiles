return {
  { "JoosepAlviste/nvim-ts-context-commentstring", lazy = true },
  {
    "echasnovski/mini.comment",
    event = "VeryLazy",
    opts = {
      options = {
        custom_commentstring = function()
          return require("ts_context_commentstring").calculate_commentstring() or vim.bo.commentstring
        end,
      },
    },
  },

  -- Todo comment highlights
  {
    "folke/todo-comments.nvim",
    event = "VeryLazy",
    opts = {
      signs = false,
    },
  },
}
