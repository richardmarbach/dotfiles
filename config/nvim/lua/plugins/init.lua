return {
  -- library used by other plugins
  { "nvim-lua/plenary.nvim", lazy = true },

  -- Use icon fonts
  { "nvim-tree/nvim-web-devicons", event = "VeryLazy", opts = {} },

  -- Text casing library
  {
    "johmsalas/text-case.nvim",
    dependencies = { "telescope.nvim" },
    config = function()
      require("textcase").setup({})
      require("telescope").load_extension("textcase")
    end,
    keys = {
      "<leader>ct", -- Default invocation prefix
      { "<leader>st", "<cmd>TextCaseOpenTelescope<CR>", mode = { "n", "x" }, desc = "Telescope" },
    },
    cmd = {
      "Subs",
      "TextCaseOpenTelescope",
      "TextCaseOpenTelescopeQuickChange",
      "TextCaseOpenTelescopeLSPChange",
      "TextCaseStartReplacingCommand",
    },
    lazy = false,
  },
}
