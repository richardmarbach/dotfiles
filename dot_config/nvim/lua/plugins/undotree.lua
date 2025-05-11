return {
  -- Navigate vim's undo tree
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    config = false,
    keys = {
      -- stylua: ignore
      { "<leader>ut", function() vim.cmd.UndotreeToggle() end, desc = "Open undo tree" },
    },
  },
}
