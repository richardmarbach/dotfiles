return {
  -- Documentation generation
  {
    "danymat/neogen",
    opts = { snippet_engine = "luasnip" },
    keys = {
      { "<Leader>ng", function() require("neogen").generate() end, silent = true, desc = "[N]eogen [G]enerate" },
    },
  },

}
