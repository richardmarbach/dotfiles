local gh = require("config.gh")

vim.pack.add({
  gh("neovim/nvim-lspconfig"),
  { src = gh("mason-org/mason.nvim"), version = vim.version.range("2") },
  gh("mason-org/mason-lspconfig.nvim"),
  gh("b0o/SchemaStore.nvim"),
})

vim.lsp.enable("lua_ls")
vim.lsp.enable("solargraph")
vim.lsp.enable("jsonls")

require("mason").setup()
require("mason-lspconfig").setup({})
