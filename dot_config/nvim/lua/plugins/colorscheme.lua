vim.pack.add({ "https://github.com/ellisonleao/gruvbox.nvim" })

vim.o.termguicolors = true
require("gruvbox").setup({
  contrast = "soft",
  overrides = {
    -- Dim full-line diff backgrounds; keep changed text (DiffText) prominent.
    DiffAdd = { bg = "#26332b" },
    DiffChange = { bg = "#2b2a22" },
    DiffDelete = { bg = "#3a2626" },
    DiffText = { bg = "#4f6c3f", bold = true },
  },
})
vim.cmd([[colorscheme gruvbox]])
