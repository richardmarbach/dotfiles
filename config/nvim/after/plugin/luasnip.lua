local ls_status_ok, ls = pcall(require, "luasnip")
if not ls_status_ok then
  return
end
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
        virt_text = { { "●", "GruvboxGray" } },
      },
    },
  },
})

vim.keymap.set("n", "<leader>ss", "<cmd>source ~/.config/nvim/after/plugin/luasnip.lua<CR>")

vim.keymap.set("n", "<leader>se", function()
  require("luasnip.loaders").edit_snippet_files({ source_name = "lua" })
end)

require("luasnip.loaders.from_lua").lazy_load({ paths = "./snippets" })
