local snippy = require("snippy")
local cmp = require("cmp")

snippy.setup({
  mappings = {
    is = {
      ["<Tab>"] = "expand_or_advance",
      ["<S-Tab>"] = "previous",
    },
    nx = {
      ["<leader>x"] = "cut_text",
    },
  },
})

cmp.setup({
  completion = {
    -- autocomplete = false,
    completeopt = "menu,menuone,noselect",
  },
  snippet = {
    expand = function(args)
      snippy.expand_snippet(args.body)
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
    { name = "buffer", max_item_count = 10 },
    { name = "snippy" },
    { name = "path" },
  },
  experimental = {
    ghost_text = true,
  },
})

vim.keymap.set("i", "<C-x><C-o", function()
  cmp.complete()
end, { noremap = true })

vim.keymap.set("i", "<C-x><C-s", function()
  cmp.complete({
    config = {
      sources = {
        { name = "snippy" },
      },
    },
  })
end, { noremap = true })
