return {
  -- Debugging
  "mfussenegger/nvim-dap",
  dependencies = {
    { "jayp0521/mason-nvim-dap.nvim", config = { automatic = true } },
  },
  keys = function()
    return {
      { "<F8>", require("dap").continue, { silent = true } },
      { "<F4>", require("dap").step_over, { silent = true } },
      { "<F5>", require("dap").step_into, { silent = true } },
      { "<F6>", require("dap").step_out, { silent = true } },
      {
        "<Leader>dt",
        require("dap").toggle_breakpoint,
        { silent = true, desc = "[D]ebug [T]oggle Breakpoint" },
      },
      {
        "<Leader>dc",
        function()
          require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end,
        { silent = true, desc = "[D]ebug Breakpoint [C]ondition" },
      },
      {
        "<Leader>dp",
        function()
          require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
        end,
        { silent = true, desc = "[D]ebug Log [P]oint message" },
      },

      { "<Leader>dr", require("dap").repl.open, { silent = true, desc = "[D]ebug [R]epl" } },
      { "<Leader>dl", require("dap").run_last, { silent = true, desc = "[D]ebug [L]ast" } },
    }
  end,
}
