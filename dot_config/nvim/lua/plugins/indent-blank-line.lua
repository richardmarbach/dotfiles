vim.pack.add({ "https://github.com/lukas-reineke/indent-blankline.nvim" })

require("ibl").setup({
  indent = { char = "┊" },
  whitespace = { remove_blankline_trail = true },
  scope = { exclude = { language = { "help" } } },
})
