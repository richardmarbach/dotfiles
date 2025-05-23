return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        sql = { "pg_format" },
        javascript = { "prettierd" },
        javascriptreact = { "prettierd" },
        typescript = { "prettierd" },
        typescriptreact = { "prettierd" },
        yaml = { "prettierd" },
        -- json = { "prettierd" },
        -- jsonc = { "prettierd" },
        css = { "prettierd" },
        scss = { "prettierd" },
        html = { "prettierd" },
        ruby = { "rubocop" },
        python = { "black" },
        terraform = { "terraform_fmt" },
      },
      default_format_opts = {
        lsp_format = "fallback",
      },
      formatters = {
        rubocop = {
          command = "bin/rubocop",
        },
      },
    },
    init = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
      require("custom.autoformat").setup()
    end,
  },
}
