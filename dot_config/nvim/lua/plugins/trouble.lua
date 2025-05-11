return {
  -- Nicer quickfix list
  {
    "folke/trouble.nvim",
    keys = {
      {
        "<leader>xx",
        function()
          require("trouble").toggle()
        end,
      },
      {
        "<leader>xw",
        function()
          require("trouble").toggle("workspace_diagnostics")
        end,
      },
      {
        "<leader>xd",
        function()
          require("trouble").toggle("document_diagnostics")
        end,
      },
      {
        "<leader>xq",
        function()
          require("trouble").toggle("quickfix")
        end,
      },
      {
        "<leader>xl",
        function()
          require("trouble").toggle("loclist")
        end,
      },
      {
        "[t",
        function()
          require("trouble").next({ skip_groups = true, jump = true })
        end,
      },
      {
        "]t",
        function()
          require("trouble").previous({ skip_groups = true, jump = true })
        end,
      },
    },
  },
}
