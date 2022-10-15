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
