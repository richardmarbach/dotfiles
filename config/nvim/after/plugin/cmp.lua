local status_ok, cmp = pcall(require, "cmp")
if not status_ok then
  return
end
local autopairs_status, cmp_autopairs = pcall(require, "nvim-autopairs.completion.cmp")
if not autopairs_status then
  return
end
cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

vim.o.completeopt = "menu,menuone,noselect"

cmp.setup({
  snippet = {
    expand = function(args)
      local snip_status_ok, luasnip = pcall(require, "luasnip")
      if not snip_status_ok then
        return
      end
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
    { name = "path" },
    { name = "nvim_lsp", keyword_length = 1 },
    { name = "luasnip", keyword_length = 1 },
    { name = "buffer", max_item_count = 10, keyword_length = 3 },
  },
  experimental = {
    ghost_text = true,
  },
})

cmp.setup.filetype("gitcommit", {
  sources = {
    { name = "github" },
    { name = "buffer", max_item_count = 10 },
    { name = "path" },
  },
})

vim.keymap.set("i", "<C-x><C-o>", function()
  cmp.complete()
end, { noremap = true })
