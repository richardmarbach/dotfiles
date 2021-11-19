local M = {}

function M.setup()
  local cmp = require('cmp')
  cmp.setup {
    completion = {
      autocomplete = false,
      completeopt='menu,menuone,noinsert'
    },
    mapping = {
      ["<C-p>"] = cmp.mapping.select_prev_item(),
      ["<C-n>"] = cmp.mapping.select_next_item(),
      ["<C-d>"] = cmp.mapping.scroll_docs(-4),
      ["<C-f>"] = cmp.mapping.scroll_docs(4),
      ["<C-Space>"] = cmp.mapping.complete(),
      ['<C-y>'] = cmp.mapping.confirm({ select = false }),
      ["<C-e>"] = cmp.mapping.close(),
      ["<CR>"] = cmp.mapping.confirm({
         behavior = cmp.ConfirmBehavior.Replace,
         select = true,
      }),
    },
    sources = {
      { name = 'nvim_lsp', max_item_count = 10},
      { name = 'buffer', max_item_count = 5 },
      { name = 'path' },
    }
  }
end

return M
