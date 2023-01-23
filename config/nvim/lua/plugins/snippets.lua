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
    },
    -- stylua: ignore
    keys = {
      {
        "<C-d>",
        function()
          return require("luasnip").jumpable(1) and "<Plug>luasnip-jump-next" or "<tab>"
        end,
        expr = true, silent = true, mode = "i",
      },
      { "<tab>", function() require("luasnip").jump(1) end, mode = "s" },
      { "<c-b>", function() require("luasnip").jump(-1) end, mode = { "i", "s" } },
    },
  },
}
