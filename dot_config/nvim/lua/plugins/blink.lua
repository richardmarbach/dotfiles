return {
  {
    "saghen/blink.cmp",
    build = "cargo build --release",
    version = "1.*",
    keys = {
      {
        "<C-x><C-o>",
        function()
          require("blink.cmp").show()
        end,
        mode = "i",
      },
    },
    ---@type blink.cmp.Config
    opts = {
      keymap = { preset = "default" },
      completion = {
        ghost_text = { enabled = true },
        menu = {
          draw = {
            columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 100,
        },
        -- trigger = {
        --   show_on_keyword = false,
        --   show_on_trigger_character = false,
        -- },
      },
      sources = {
        default = { "lsp", "path", "snippets", "copilot", "buffer" },
        providers = {
          lazydev = { module = "lazydev.integrations.blink", score_offset = 100 },
          lsp = { fallbacks = {} }, -- fallback to buffer
          copilot = {
            name = "copilot",
            module = "blink-cmp-copilot",
            score_offset = 100,
            async = true,
          },
        },
        per_filetype = {
          lua = { inherit_defaults = true, "lazydev" },
        },
      },
      signature = { enabled = true },
      fuzzy = { implementation = "prefer_rust_with_warning" },
      snippets = { preset = "luasnip" },
    },
    opts_extend = { "sources.default" },
  },
  {
    "zbirenbaum/copilot.lua",
    config = function()
      require("copilot").setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
      })
    end,
  },
  {
    "giuxtaposition/blink-cmp-copilot",
  },
}
