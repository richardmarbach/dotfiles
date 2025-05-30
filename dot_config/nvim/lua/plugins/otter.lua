return {
  -- LSP in embedded documents
  {
    "jmbuhr/otter.nvim",
    config = function()
      -- enable for toml files
      vim.api.nvim_create_autocmd({ "FileType" }, {
        pattern = { "toml" },
        group = vim.api.nvim_create_augroup("EmbedToml", {}),
        callback = function()
          require("otter").activate()
        end,
      })
    end,
  },
}
