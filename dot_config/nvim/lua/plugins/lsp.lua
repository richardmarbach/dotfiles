return {
  { "b0o/SchemaStore.nvim" },
  { "neovim/nvim-lspconfig" },

  {
    "mason-org/mason.nvim",
    version = "v2.*",
    cmd = "Mason",
    config = function()
      require("mason").setup()
    end,
  },

  {
    "mason-org/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("mason-lspconfig").setup()
    end,
  },
}
