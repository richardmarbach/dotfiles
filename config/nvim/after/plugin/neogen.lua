require('neogen').setup({ snippet_engine = "luasnip" })

vim.keymap.set("n", "<Leader>ng", require('neogen').generate, {
  silent = true,
  desc = "[N]eogen [G]enerate"
})
