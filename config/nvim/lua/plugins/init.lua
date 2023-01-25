return {
  "tpope/vim-sleuth", -- Detect tabstop and shiftwidth automatically

  -- Text casing library
  { "johmsalas/text-case.nvim", lazy = true },

  -- library used by other plugins
  { "nvim-lua/plenary.nvim", lazy = true },

  -- Use icon fonts
  { "nvim-tree/nvim-web-devicons", event = "VeryLazy", opts = {} },
}
