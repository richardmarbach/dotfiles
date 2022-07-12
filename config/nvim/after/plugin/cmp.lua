local luasnip = require("luasnip")
local cmp = require("cmp")

vim.o.completeopt = "menuone,noselect"

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = {
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-n>"] = cmp.mapping.select_next_item(),
    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-y>"] = cmp.mapping.confirm({ select = false }),
    ["<C-e>"] = cmp.mapping.close(),
    ["<C-Space>"] = cmp.mapping.confirm(),
  },
  sources = {
    { name = "github" },
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "buffer", max_item_count = 10 },
    { name = "path" },
  },
  experimental = {
    ghost_text = true,
  },
})

vim.keymap.set("i", "<C-x><C-o>", function()
  cmp.complete()
end, { noremap = true })

vim.keymap.set("i", "<C-x><C-s>", function()
  cmp.complete({
    config = {
      sources = {
        { name = "luasnip" },
      },
    },
  })
end, { noremap = true })
