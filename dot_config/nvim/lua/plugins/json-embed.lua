return {
  {
    "richardmarbach/json-embed.nvim",
    name = "json-embed",
    cmd = { "JSONEmbedEdit" },
    keys = {
      {
        "<leader>je",
        function()
          require("json-embed").edit_embedded()
          require("plugins.lsp.format").format()
        end,
        silent = true,
        desc = "Edit json embedded language under cursor",
      },
    },
    opts = { ft = "sql" },
  },
}
