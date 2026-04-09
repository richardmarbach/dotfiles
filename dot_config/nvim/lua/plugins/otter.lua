vim.pack.add({ "https://github.com/jmbuhr/otter.nvim" })

vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "toml" },
  group = vim.api.nvim_create_augroup("EmbedToml", {}),
  callback = function()
    require("otter").activate()
  end,
})
