return {
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

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "folke/lazydev.nvim",
      "mason.nvim",
      "mason-lspconfig.nvim",
      "saghen/blink.cmp",
      "b0o/SchemaStore.nvim",
    },
  },
}
