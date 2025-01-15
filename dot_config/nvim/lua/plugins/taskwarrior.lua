return {
  "ribelo/taskwarrior.nvim",
  dependencies = { "telescope.nvim" },
  opt = {},
  cmd = {
    "Task",
  },
  keys = {
    {
      "<leader>st",
      function()
        require("taskwarrior_nvim").browser({ "ready" })
      end,
      mode = { "n", "x" },
      desc = "Telescope",
    },
  },
}
