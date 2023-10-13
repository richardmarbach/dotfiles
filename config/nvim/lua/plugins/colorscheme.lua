return {
  "ellisonleao/gruvbox.nvim", -- Theme inspired by Atom
  lazy = false, -- make sure we load this during startup if it is your main colorscheme
  priority = 1000, -- make sure to load this before all the other start plugins
  config = function()
    -- Set colorscheme
    vim.o.termguicolors = true

    require("gruvbox").setup({
      contrast = "soft",
    })
    vim.cmd([[colorscheme gruvbox]])
  end,
}
