return {
  -- -- Debugging
  -- "mfussenegger/nvim-dap",
  -- dependencies = {
  --   { "jayp0521/mason-nvim-dap.nvim", config = { automatic = true } },
  --   { "suketa/nvim-dap-ruby", config = true },
  --   { "theHamsta/nvim-dap-virtual-text", config = true },
  -- },
  -- -- stylua: ignore
  -- keys = {
  --   { "<F12>", function() require("dap").continue() end, { silent = true } },
  --   { "<F7>", function() require("dap").step_over() end, { silent = true } },
  --   { "<F8>", function() require("dap").step_into() end, { silent = true } },
  --   { "<F9>", function() require("dap").step_out() end, { silent = true } },
  --   { "<F6>", function() require("dap").toggle_breakpoint() end, { silent = true, desc = "[D]ebug [T]oggle Breakpoint" } },
  --   { "<Leader>dc",
  --     function()
  --       require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
  --     end,
  --     { silent = true, desc = "[D]ebug Breakpoint [C]ondition" },
  --   },
  --   {
  --     "<Leader>dp",
  --     function()
  --       require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
  --     end,
  --     { silent = true, desc = "[D]ebug Log [P]oint message" },
  --   },
  --   { "<Leader>dr", function() require("dap").repl.open() end, { silent = true, desc = "[D]ebug [R]epl" } },
  --   { "<Leader>dl", function() require("dap").run_last() end, { silent = true, desc = "[D]ebug [L]ast" } },
  -- },
}
