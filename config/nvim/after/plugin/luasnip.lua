local ls = require("luasnip")
local types = require("luasnip.util.types")

ls.config.setup({
  -- This tells LuaSnip to remember to keep around the last snippet.
  -- You can jump back into it even if you move outside of the selection
  history = true,
  -- This one is cool cause if you have dynamic snippets, it updates as you type!
  updateevents = "TextChanged,TextChangedI",
  delete_check_events = "TextChanged,InsertLeave",
  region_check_events = "InsertEnter",

  -- Autosnippets:
  enable_autosnippets = true,

  ext_opts = {
    [types.choiceNode] = {
      active = {
        virt_text = { { "●", "GruvboxOrange" } },
      },
    },
    [types.insertNode] = {
      active = {
        virt_text = { { "●", "GruvboxBlue" } },
      },
    },
  },
})

vim.keymap.set("n", "<leader>ss", "<cmd>source ~/.config/nvim/after/plugin/luasnip.lua<CR>")

vim.keymap.set("n", "<leader>se", function()
  local ft = vim.bo.filetype
  vim.cmd("tabnew ~/.config/nvim/snippets/" .. ft .. ".lua")
end)

require("luasnip.loaders.from_lua").lazy_load({ paths = "./snippets" })
