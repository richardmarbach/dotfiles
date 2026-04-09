vim.cmd.packadd("nvim.undotree")

vim.keymap.set("n", "<leader>ut", function()
  require("undotree").open()
end, { desc = "Open undo tree" })
