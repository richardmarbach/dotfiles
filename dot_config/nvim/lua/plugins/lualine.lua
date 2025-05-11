return {
  -- Fancier statusline
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function()
      return {
        options = {
          icons_enabled = false,
          theme = "gruvbox",
          component_separators = "|",
          section_separators = "",
        },
      }
    end,
  },
}
