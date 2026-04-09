local gh = require("config.gh")

vim.pack.add({
  gh("nvim-lua/plenary.nvim"),
  gh("nvim-tree/nvim-web-devicons"),
  gh("richardmarbach/extract-ruby-constant"),
})
require("nvim-web-devicons").setup({})

for _, path in ipairs(vim.fn.glob(vim.fn.stdpath("config") .. "/lua/plugins/*.lua", false, true)) do
  local name = vim.fn.fnamemodify(path, ":t:r")
  require("plugins." .. name)
end
