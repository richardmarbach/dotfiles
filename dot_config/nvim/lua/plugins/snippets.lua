vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name == "LuaSnip" and (ev.data.kind == "install" or ev.data.kind == "update") then
      vim.system({ "make", "install_jsregexp" }, { cwd = ev.data.path }):wait()
    end
  end,
})

vim.pack.add({
  { src = "https://github.com/L3MON4D3/LuaSnip", version = vim.version.range("2") },
})

local types = require("luasnip.util.types")

require("luasnip").setup({
  enable_autosnippets = true,
  history = true,
  region_check_events = "CursorHold,InsertLeave,InsertEnter",
  delete_check_events = "TextChanged,InsertEnter",
  update_events = "TextChanged,TextChangedI",
  store_selection_keys = "<C-D>",
  ext_opts = {
    [types.choiceNode] = {
      active = {
        virt_text = { { " « ", "NonText" } },
      },
    },
  },
})
require("luasnip.loaders.from_lua").lazy_load({ paths = "./snippets" })
