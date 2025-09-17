return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "b0o/SchemaStore.nvim",
    },
    config = function()
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      })
      vim.lsp.enable("lua_ls")

      vim.lsp.config("solargraph", {
        init_options = {
          formatting = false,
        },
        settings = {
          solargraph = {
            diagnostics = true,
          },
        },
      })
      vim.lsp.enable("solargraph")

      vim.lsp.config("jsonls", {
        settings = {
          json = {
            format = {
              enable = true,
            },
            validate = { enable = true },
            schemas = require("schemastore").json.schemas(),
          },
        },
      })
      vim.lsp.enable("jsonls")

      -- vim.lsp.config("ts_ls", {
      --   root_markers = { ".git" },
      -- })
      -- vim.lsp.enable("ts_ls")
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
    config = function()
      require("mason-lspconfig").setup()
    end,
  },
}
