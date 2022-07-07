local ls = require("luasnip")
local types = require("luasnip.util.types")

ls.config.setup({
  -- This tells LuaSnip to remember to keep around the last snippet.
  -- You can jump back into it even if you move outside of the selection
  history = true,
  -- This one is cool cause if you have dynamic snippets, it updates as you type!
  updateevents = "TextChanged,TextChangedI",

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

vim.keymap.set({ "i", "s" }, "<Tab>", function()
  print(vim.inspect(ls.expand_or_jumpable()))
  if ls.expand_or_jumpable() then
    ls.expand_or_jump()
  end
end, { silent = true })

vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
  if ls.jumpable(-1) then
    ls.jump(-1)
  end
end, { silent = true })

vim.keymap.set("i", "<c-E>", function()
  if ls.choice_active() then
    ls.change_choice(1)
  end
end)

vim.keymap.set("n", "<leader>ss", "<cmd>source ~/.config/nvim/after/plugin/luasnip.lua<CR>")

-- Load Existing snippet plugin
require("luasnip.loaders.from_vscode").lazy_load()
ls.filetype_extend("ruby", { "rails" })
