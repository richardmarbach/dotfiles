return {
  {
    "L3MON4D3/LuaSnip",
    dependencies =  {
          { "rafamadriz/friendly-snippets" },
    { "saadparwaiz1/cmp_luasnip" },

    },
    config = function()
    local luasnip = require("luasnip")
    require("neogen")
    luasnip.config.set_config({
        enable_autosnippets = true,
      region_check_events = "InsertEnter",
      delete_check_events = "InsertLeave",
    })
          require("luasnip.loaders.from_vscode").lazy_load()
    end
  }
}
