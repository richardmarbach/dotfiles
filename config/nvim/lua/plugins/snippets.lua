return {
  {
    "L3MON4D3/LuaSnip",
    dependencies = {
      "rafamadriz/friendly-snippets",
      config = function()
        require("luasnip.loaders.from_vscode").lazy_load()
      end,
    },
    opts = {
      enable_autosnippets = true,
      region_check_events = "InsertEnter",
      delete_check_events = "InsertLeave",
      store_selection_keys = "<C-D>",
    },
  },
}
