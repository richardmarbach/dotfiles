return {
  "olimorris/codecompanion.nvim",
  opts = {
    opts = {
      log_level = "DEBUG",
    },
    strategies = {
      chat = {
        adapter = "copilot",
        keymaps = {
          close = {
            modes = { n = "<C-c>", i = "<C-c>" },
          },
        },
      },
      inline = {
        adapter = "copilot",
        keymaps = {
          accept_change = {
            modes = { n = "ga" },
            description = "Accept the suggested change",
          },
          reject_change = {
            modes = { n = "gr" },
            description = "Reject the suggested change",
          },
        },
      },
    },
    adapters = {
      copilot = function()
        return require("codecompanion.adapters").extend("copilot", {
          schema = {
            model = {
              default = "claude-3.7-sonnet",
            },
          },
        })
      end,
      openai = function()
        return require("codecompanion.adapters").extend("openai", {
          env = {
            api_key = "cmd:op read 'op://Private/OpenAI CodeCompanion/password' --no-newline",
          },
          schema = {
            model = {
              default = "o3-mini",
            },
          },
        })
      end,
    },
  },
  keys = {
    { "<leader>ca", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" } },
    { "<LocalLeader>co", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" } },
  },
  setup = function(_, opts)
    require("codecompanion").setup(opts)
    -- Expand 'cc' into 'CodeCompanion' in the command line
    vim.cmd([[cab cc CodeCompanion]])
  end,
}
