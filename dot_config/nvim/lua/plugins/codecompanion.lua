return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "plenary.nvim",
    "nvim-treesitter",
  },
  opts = {
    adapters = {
      openai = function()
        return require("codecompanion.adapters").extend("openai", {
          env = {
            api_key = "cmd:op read 'op://Private/OpenAI CodeCompanion/password' --no-newline",
          },
        })
      end,
    },
  },
  keys = {
    { "<C-a>", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" } },
    { "<LocalLeader>ca", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" } },
    { "ga", "<cmd>CodeCompanionChat Add<cr>", mode = "v" },
  },
  setup = function(_, opts)
    require("codecompanion").setup(opts)
    -- Expand 'cc' into 'CodeCompanion' in the command line
    vim.cmd([[cab cc CodeCompanion]])
  end,
}
