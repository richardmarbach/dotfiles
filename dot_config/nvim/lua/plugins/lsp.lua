return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "b0o/SchemaStore.nvim",
    },
    config = function()
      vim.lsp.enable("ts_ls")
      vim.lsp.enable("solargraph")
      vim.lsp.enable("jsonls")
      vim.lsp.enable("lua_ls")
    end,
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
