return {
  -- Detect tabstop and shiftwidth automatically
  { "NMAC427/guess-indent.nvim", event = "VeryLazy", opts = {} },

  {
    "stevearc/oil.nvim",
    cmd = { "Oil" },
    keys = {
      { "<leader>se", "<cmd>Oil<cr>", { desc = "Open Oil" } },
    },
    opts = {
      default_file_explorer = true,
    },
    lazy = false,
  },

  -- Tmux integration
  {
    "EvWilson/slimux.nvim",
    config = function()
      local slimux = require("slimux")
      slimux.setup({
        target_socket = slimux.get_tmux_socket(),
        target_pane = "left",
        -- target_pane = string.format("%s.0", slimux.get_tmux_window()),
      })
      vim.keymap.set(
        "v",
        "<leader>ts",
        ':lua require("slimux").send_highlighted_text()<CR>',
        { desc = "Send currently highlighted text to configured tmux pane" }
      )
      vim.keymap.set(
        "n",
        "<leader>ts",
        ':lua require("slimux").send_paragraph_text()<CR>',
        { desc = "Send paragraph under cursor to configured tmux pane" }
      )
    end,
  },
}
