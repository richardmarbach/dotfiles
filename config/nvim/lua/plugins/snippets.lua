return {
  {
    "L3MON4D3/LuaSnip",
    opts = function()
      local types = require("luasnip.util.types")

      return {
        enable_autosnippets = true,
        region_check_events = "InsertEnter",
        delete_check_events = "InsertLeave",
        store_selection_keys = "<C-D>",
        ext_opts = {
          [types.choiceNode] = {
            active = {
              virt_text = { { "", "GruvboxOrange" } },
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
