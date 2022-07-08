-- 24 bit colors
vim.o.termguicolors = true

vim.o.background = "dark"
require("gruvbox").setup({
  contrast = "soft",
})
vim.cmd("colorscheme gruvbox")
