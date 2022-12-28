vim.keymap.set("n", "<F8>", require("dap").continue, { silent = true })
vim.keymap.set("n", "<F4>", require("dap").step_over, { silent = true })
vim.keymap.set("n", "<F5>", require("dap").step_into, { silent = true })
vim.keymap.set("n", "<F6>", require("dap").step_out, { silent = true })
vim.keymap.set(
  "n",
  "<Leader>dt",
  require("dap").toggle_breakpoint,
  { silent = true, desc = "[D]ebug [T]oggle Breakpoint" }
)
vim.keymap.set("n", "<Leader>dc", function()
  require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { silent = true, desc = "[D]ebug Breakpoint [C]ondition" })
vim.keymap.set("n", "<Leader>dp", function()
  require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
end, { silent = true, desc = "[D]ebug Log [P]oint message" })

vim.keymap.set("n", "<Leader>dr", require("dap").repl.open, { silent = true, desc = "[D]ebug [R]epl" })
vim.keymap.set("n", "<Leader>dl", require("dap").run_last, { silent = true, desc = "[D]ebug [L]ast" })
