return {
  -- Add indentation guides even on blank lines
  {
    "lukas-reineke/indent-blankline.nvim",
    config = {
      char = "┊",
      show_trailing_blankline_indent = false,
    },
  },

  -- Fancier statusline
  {
    "nvim-lualine/lualine.nvim",
    config = {
      options = {
        icons_enabled = false,
        theme = "gruvbox",
        component_separators = "|",
        section_separators = "",
      },
    },
  },

  -- Useful status updates for LSP
  { "j-hui/fidget.nvim", config = true },
}
