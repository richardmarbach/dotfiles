vim.pack.add({ "https://github.com/ellisonleao/gruvbox.nvim" })

vim.o.termguicolors = true
require("gruvbox").setup({ contrast = "soft" })
vim.cmd([[colorscheme gruvbox]])
