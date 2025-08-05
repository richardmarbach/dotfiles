return {
  {
    "neovim/nvim-lspconfig",
    event = "VeryLazy",
    dependencies = {
      "mason.nvim",
      "b0o/SchemaStore.nvim",
      { "mason-org/mason-lspconfig.nvim", config = function() end },
    },
  },

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
