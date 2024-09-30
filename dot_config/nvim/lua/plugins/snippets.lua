return {
  {
    "L3MON4D3/LuaSnip",
    opts = function()
      local types = require("luasnip.util.types")

      return {
        enable_autosnippets = true,
        history = true,
        region_check_events = "CursorHold,InsertLeave,InsertEnter",
        delete_check_events = "TextChanged,InsertEnter",
        update_events = "TextChanged,TextChangedI",
        store_selection_keys = "<C-D>",
        ext_opts = {
          [types.choiceNode] = {
            active = {
              virt_text = { { " « ", "NonText" } },
            },
          },
        },
      }
    end,
    config = function(_, opts)
      require("luasnip").setup(opts)
      require("luasnip.loaders.from_lua").lazy_load({ paths = "./snippets" })
    end,
  },
}
