local M = {}

vim.o.completeopt = 'menu,menuone,noselect'

local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

function M.setup()
  local snippy = require("snippy")
  local cmp = require('cmp')

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

  cmp.setup {
    completion = {
      -- autocomplete = false,
      -- completeopt='menu,menuone,noinsert'
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
      ['<C-y>'] = cmp.mapping.confirm({ select = false }),
      ["<C-e>"] = cmp.mapping.close(),
      ["<CR>"] = cmp.mapping.confirm({
         behavior = cmp.ConfirmBehavior.Replace,
         select = true,
      }),
      ['<C-Space>'] = cmp.mapping.confirm(),
    },
    sources = {
      { name = 'nvim_lsp', max_item_count = 10},
      { name = 'snippy' },
      { name = 'buffer', max_item_count = 5 },
      { name = 'path' },
    },
    experimental = {
      ghost_test = true
    },
  }
end

return M
